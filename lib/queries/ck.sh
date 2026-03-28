#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/ck.sh — ck semantic search helpers
#
# Provides: Query::ck_find_roots  Query::safe_ck  Query::_run_ck_semantic

# Query::ck_find_roots — print src if it contains a .ck index, otherwise nothing.
# Yields src itself so _ck_root always matches the provided input folder arg.
Query::ck_find_roots() {
  local src="$1"
  [[ -d "${src}/.ck" ]] && echo "${src}"
}

# Query::safe_ck — ck exits 1 when no matches are found; treat that as success.
# Silently skips if ck is not installed.
Query::safe_ck() {
  command -v ck &>/dev/null || return 0
  ck "$@" || [[ $? -eq 1 ]]
}

# Query::_run_ck_semantic — run one ck query and write JSONL to stdout.
# Callers redirect stdout to the desired output file (>> file.jsonl).
#
# $1  query    — natural language (sem/hybrid/lex) or regex search phrase
# $2  ck_root  — directory containing a .ck index
#
# CK_SEARCH_TYPE   sem | lex | regex | hybrid  (default: sem)
# CK_THRESHOLD     0.0–1.0                      (default: 0.5, sem/lex/hybrid only)
# CK_RERANK        true | false                 (default: false; true → forces hybrid/RRF)
# CK_TOPK          integer                      (default: 50)
# CK_FULL_SECTION  true | false                 (default: true; returns complete functions)
Query::_run_ck_semantic() {
  local query="$1"
  local ck_root="$2"

  local _search_type="${CK_SEARCH_TYPE:-sem}"
  local _threshold="${CK_THRESHOLD:-0.5}"
  local _rerank="${CK_RERANK:-false}"
  local _topk="${CK_TOPK:-50}"
  local _full_section="${CK_FULL_SECTION:-true}"

  # Reranking via RRF requires hybrid mode; upgrade silently if requested
  [[ "${_rerank}" == "true" && "${_search_type}" != "hybrid" ]] && _search_type="hybrid"

  local -a ck_flags=(--jsonl --topk "${_topk}")
  case "${_search_type}" in
    sem)    ck_flags+=(--sem    --threshold "${_threshold}") ;;
    lex)    ck_flags+=(--lex    --threshold "${_threshold}") ;;
    hybrid) ck_flags+=(--hybrid --threshold "${_threshold}") ;;
    regex)  ck_flags+=(--regex) ;;
    *)      ck_flags+=(--sem    --threshold "${_threshold}") ;;
  esac
  [[ "${_full_section}" == "true" ]] && ck_flags+=(--full-section)

  # ck info lines (model, config) go to stderr; redirect so only JSONL hits stdout.
  # Real field names in ck v0.7+: .path (not .file), .snippet (not .preview).
  # Fall back to span description when snippet is absent.
  Query::safe_ck "${ck_flags[@]}" "${query}" "${ck_root}" 2>/dev/null | \
    jq -r 'select(type == "object") | select(.path != null) | {
      file:  .path,
      line:  (.span.line_start // 0),
      score: (.score   // 0),
      match: (.snippet // ("lines \(.span.line_start // 0)-\(.span.line_end // 0)"))
    }'
}
