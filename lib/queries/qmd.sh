#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source=lib/config.sh
# lib/queries/qmd.sh — qmd semantic search helpers
#
# Provides: Query::qmd_find_collections  Query::safe_qmd  Query::_run_qmd_semantic

# Query::qmd_find_collections — check if qmd index exists for a source directory.
# Uses qmd status to discover indexed collections; yields matching collection names.
Query::qmd_find_collections() {
  local src="$1"
  # qmd stores index in ~/.qmd by default; collections are paths indexed.
  # We check if any indexed collection overlaps with the source path.
  command -v qmd &>/dev/null || return 0
  qmd status --json 2>/dev/null | \
    jq -r --arg src "$src" '
      .collections[]?
      | select(.path | startswith($src) or $src | startswith(.path))
      | .name
    '
}

# Query::safe_qmd — qmd exits non-zero on errors; treat no-results as success.
# Silently skips if qmd is not installed.
Query::safe_qmd() {
  command -v qmd &>/dev/null || return 0
  qmd "$@" || [[ $? -eq 1 ]]
}

# Query::_run_qmd_semantic — run one qmd query and write JSONL to stdout.
# Callers redirect stdout to the desired output file (>> file.jsonl).
#
# $1  query     — natural language search phrase
# $2  collection — qmd collection name to search (or empty for all)
#
# QMD_SEARCH_MODE  query | vsearch | search  (default: query = hybrid)
# QMD_MIN_SCORE    0.0–1.0                      (default: 0.3)
# QMD_TOPK         integer                      (default: 50)
# QMD_FULL         true | false                 (default: true; returns complete document)
Query::_run_qmd_semantic() {
  local query="$1"
  local collection="$2"

  local _mode="${QMD_SEARCH_MODE:-query}"
  local _min_score="${QMD_MIN_SCORE:-0.3}"
  local _topk="${QMD_TOPK:-50}"
  local _full="${QMD_FULL:-true}"

  local -a qmd_flags=(--json --topk "${_topk}" --min-score "${_min_score}")
  [[ "${_full}" == "true" ]] && qmd_flags+=(--full)

  # qmd info lines go to stderr; redirect so only JSON hits stdout.
  # qmd JSON output: array of objects with .file, .title, .score, .snippet, .path
  Query::safe_qmd "${_mode}" "${qmd_flags[@]}" --collection "${collection}" "${query}" 2>/dev/null | \
    jq -r '
      .[] |
      select(.path != null) |
      {
        file:  .path,
        line:  0,
        score: (.score // 0),
        match: (.snippet // .title // "no snippet")
      }'
}