#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/search.sh — Query::run_search
#
# Searches for hybrid search, reciprocal rank fusion, and retrieval patterns.
# Depends on: helpers.sh  ck.sh

Query::run_search() {
  local src="$1"
  local out="$2/search"
  Query::_ensure_dir "${out}"

  Query::_write_raw_chunks \
    "${out}/raw/hybrid_patterns" \
    'hybrid.*search|reciprocal.*rank|rrf|fusion' \
    "${src}" "py, ruby, markdown" 10 50 \
    -n -i 'hybrid.*search|reciprocal.*rank|rrf|fusion' \
    --type py --type ruby --type markdown \
    --context 10 --max-count 50 \
    "${src}"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "hybrid search reciprocal rank fusion retrieval augmented dense sparse" \
      "${_ck_root}" >> "${out}/hybrid_patterns_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
