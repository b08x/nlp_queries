#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/configs.sh — Query::run_configs
#
# Searches for context window sizes and token limit configuration parameters.
# Depends on: helpers.sh  qmd.sh

Query::run_configs() {
  local src="$1"
  local out="$2/config"
  Query::_ensure_dir "${out}"

  Query::_write_raw_chunks \
    "${out}/raw/context_windows" \
    'context.*(window|size|length)|max.*(token|length|context)' \
    "${src}" "json, yaml, py, markdown" 10 75 \
    -n 'context.*(window|size|length)|max.*(token|length|context)' \
    --type json --type yaml --type py --type markdown \
    --context 10 --max-count 75 \
    "${src}"

  local _collection
  while IFS= read -r _collection; do
    Query::_run_qmd_semantic \
      "context window size token limit configuration parameters settings" \
      "${_collection}" >> "${out}/context_windows_semantic.jsonl"
  done < <(Query::qmd_find_collections "${src}")
}
