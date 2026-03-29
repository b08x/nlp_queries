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
    # write_chunk — flush accumulated lines to dest/chunk_NNNN.md
    # fname is a local variable (awk extra-param idiom)
    function write_chunk(    fname) {
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
      idx++; sf = ""; sl = 0; chunk = ""
    }
    BEGIN { idx = 0; sf = ""; sl = 0; chunk = "" }
    /^--$/ { write_chunk(); next }
    {
      # Extract source file and line from the first match line (file:line:content).
      # Context lines use "-" as separator and are skipped here.
      if (sf == "" && $0 ~ /^[^:]+:[0-9]+:/) {
        colon1 = index($0, ":")
        sf    = substr($0, 1, colon1 - 1)
        rest  = substr($0, colon1 + 1)
        colon2 = index(rest, ":")
        sl    = substr(rest, 1, colon2 - 1)
      }
      # Strip the source-file prefix from match lines (file:line:content) and
      # context lines (file-line-content), retaining only line-number and content.
      line = $0
      if (sf != "" && substr(line, 1, length(sf) + 1) == sf ":") {
        line = substr(line, length(sf) + 2)
      } else if (sf != "" && substr(line, 1, length(sf) + 1) == sf "-") {
        line = substr(line, length(sf) + 2)
      }
      chunk = (chunk == "") ? line : chunk "\n" line
    }
    END { write_chunk() }
  '
}
