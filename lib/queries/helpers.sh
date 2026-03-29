#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/helpers.sh — Shared internals for all Query:: functions
#
# Provides: Query::_ensure_dir  Query::safe_rga  Query::_write_raw_chunks

Query::_ensure_dir() {
  mkdir -p "$1"
}

# Query::safe_rga — rga exits 1 when no matches are found; treat that as
# success (zero results) rather than a script error.
Query::safe_rga() {
  rga \
    --ignore-file="${HOME}/.gitignore" \
    --hidden \
    --rga-accurate \
    --rga-adapters='poppler,pandoc' \
    -j 4 \
    "$@" || [[ $? -eq 1 ]]
}

# Query::_write_raw_chunks — split rga context output into one .md file per
# '--'-delimited match group, each with YAML frontmatter.
#
# $1  dest_dir — directory to write chunk_NNNN.md files into (created if absent)
# $2  query    — regex pattern recorded in frontmatter (display only)
# $3  source   — source directory being searched
# $4  types    — YAML inline list contents, e.g. "py, ruby, json"
# $5  ctx      — --context line count
# $6  maxc     — --max-count value, or ~ for none
# $7+ …        — forwarded verbatim to Query::safe_rga
#
# Note: backslashes in query are doubled before awk -v assignment to prevent
# awk from interpreting \b, \w, etc. as escape sequences.
Query::_write_raw_chunks() {
  local dest_dir="$1"
  local query="$2"
  local source="$3"
  local types="$4"
  local ctx="$5"
  local maxc="$6"
  shift 6

  Query::_ensure_dir "${dest_dir}"

  local _ts
  _ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Double backslashes so awk -v does not interpret \b \w \. as escape sequences
  local _awk_query="${query//\\/\\\\}"

  Query::safe_rga "$@" | awk \
    -v dest="${dest_dir}" \
    -v q="${_awk_query}" \
    -v src="${source}" \
    -v t="${types}" \
    -v c="${ctx}" \
    -v m="${maxc}" \
    -v ts="${_ts}" '
    # fmt_line — strip the source-file prefix from a raw rga output line
    # (both "file:linenum:content" match lines and "file-linenum-content"
    # context lines), then normalise the linenum separator to ": ".
    function fmt_line(raw) {
      if (sf != "" && substr(raw, 1, length(sf) + 1) == sf ":") {
        raw = substr(raw, length(sf) + 2)
      } else if (sf != "" && substr(raw, 1, length(sf) + 1) == sf "-") {
        raw = substr(raw, length(sf) + 2)
      }
      if (match(raw, /^[0-9]+[-:]/))
        raw = substr(raw, 1, RLENGTH - 1) ": " substr(raw, RLENGTH + 1)
      return raw
    }
    # write_chunk — flush accumulated lines to dest/chunk_NNNN.md
    # Extra params after the first space are awk local variables (idiom).
    function write_chunk(    fname, i) {
      if (chunk == "") return
      fname = dest "/chunk_" sprintf("%04d", idx) ".md"
      print "---"                       > fname
      print "query: \""     q  "\""    > fname
      print "source_file: \"" sf "\""  > fname
      print "line: "        sl         > fname
      print "source: \""    src "\""   > fname
      print "types: ["      t  "]"    > fname
      print "context_lines: " c        > fname
      print "max_count: "    m         > fname
      print "generated_at: \"" ts "\"" > fname
      print "---"                       > fname
      print ""                          > fname
      print chunk                       > fname
      close(fname)
      idx++; sf = ""; sl = 0; chunk = ""; prebuf_n = 0
    }
    BEGIN { idx = 0; sf = ""; sl = 0; chunk = ""; prebuf_n = 0 }
    /^--$/ { write_chunk(); next }
    {
      # First match line in a group — sets sf and sl, then flushes the
      # pre-context buffer (lines that arrived before sf was known).
      if (sf == "" && $0 ~ /^[^:]+:[0-9]+:/) {
        colon1 = index($0, ":")
        sf    = substr($0, 1, colon1 - 1)
        rest  = substr($0, colon1 + 1)
        colon2 = index(rest, ":")
        sl    = substr(rest, 1, colon2 - 1)

        # Retroactively format buffered pre-context lines now that sf is known,
        # and append them to chunk in arrival order.
        for (i = 0; i < prebuf_n; i++) {
          pline = fmt_line(prebuf[i])
          chunk = (chunk == "") ? pline : chunk "\n" pline
        }
        prebuf_n = 0
      }

      # Pre-context: sf not yet known — buffer until the match line arrives.
      if (sf == "") {
        prebuf[prebuf_n++] = $0
        next
      }

      line = fmt_line($0)
      chunk = (chunk == "") ? line : chunk "\n" line
    }
    END { write_chunk() }
  '
}
