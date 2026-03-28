#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/configs.sh — Query::run_configs
#
# Searches for context window sizes and token limit configuration parameters.
# Depends on: helpers.sh  ck.sh

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

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "context window size token limit configuration parameters settings" \
      "${_ck_root}" >> "${out}/context_windows_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
