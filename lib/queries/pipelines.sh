#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/pipelines.sh — Query::run_pipelines
#
# Searches for RAG pipeline class/function definitions and architectures.
# Depends on: helpers.sh  ck.sh

Query::run_pipelines() {
  local src="$1"
  local out="$2/pipelines"
  Query::_ensure_dir "${out}"

  Query::_write_raw_chunks \
    "${out}/raw/architectures" \
    'class \w*Pipeline|def.*pipeline' \
    "${src}" "ruby, py, markdown" 20 50 \
    -n 'class \w*Pipeline|def.*pipeline' \
    --type ruby --type py --type markdown \
    --context 20 --max-count 50 \
    "${src}"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "RAG pipeline architecture stages ingestion retrieval augmented generation" \
      "${_ck_root}" >> "${out}/architectures_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
