#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/parsers.sh — Query::run_parsers
#
# Searches for markdown document parsing and section-splitting patterns.
# Depends on: helpers.sh  ck.sh

Query::run_parsers() {
  local src="$1"
  local out="$2/parsers"
  Query::_ensure_dir "${out}"

  Query::_write_raw_chunks \
    "${out}/raw/markdown_splitters" \
    'markdown.*(split|chunk|section|header)' \
    "${src}" "ruby, py, js, markdown" 10 75 \
    -n -i 'markdown.*(split|chunk|section|header)' \
    --type ruby --type py --type js --type markdown \
    --context 10 --max-count 75 \
    "${src}"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "markdown document parsing splitting by headers sections structure" \
      "${_ck_root}" >> "${out}/markdown_splitters_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
