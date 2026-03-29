#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/chunking.sh — Query::run_chunking
#
# Searches for text chunking strategies, token window configs, and hierarchical
# splitting patterns. Depends on: helpers.sh  ck.sh

Query::run_chunking() {
  local src="$1"
  local out="$2/chunking"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'chunk.*strateg|semantic.*split|text.*segment' \
    --type markdown --type pdf --type ruby --type typescript --type json --type py \
    "${src}" --json | \
    jq -r 'select(type == "object") |
           select(.type == "match") |
           select(.data != null) |
           {
             file:  (.data.path.text        // "unknown"),
             line:  (.data.line_number       // 0),
             match: (.data.lines.text        // "")
           } |
           select(.match != "")' \
    > "${out}/strategies.jsonl"

  Query::safe_rga -i 'token.*window|max.*token' \
    --type py --type ruby --type json --type markdown \
    "${src}" --json | \
    jq -r 'select(.type == "match") |
           select(.data.lines.text != null) |
           {
             source:  .data.path.text,
             line:    (.data.line_number // 0),
             content: .data.lines.text
           }' \
    > "${out}/token_configs.jsonl"

  Query::_write_raw_chunks \
    "${out}/raw/hierarchical" \
    '(recursive|hierarch|tree).{0,25}(chunk|split)' \
    "${src}" "markdown, py, ruby" 10 75 \
    -n -i '(recursive|hierarch|tree).{0,25}(chunk|split)' \
    --type markdown --type py --type ruby \
    --context 10 --max-count 75 \
    "${src}"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "text chunking strategies recursive splitting semantic segmentation" \
      "${_ck_root}" >> "${out}/strategies_semantic.jsonl"
    Query::_run_ck_semantic \
      "token window size maximum token limits configuration" \
      "${_ck_root}" >> "${out}/token_configs_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
