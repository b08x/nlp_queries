#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/graphs.sh — Query::run_graphs
#
# Searches for knowledge graph, triple store, and entity-relation patterns.
# Depends on: helpers.sh  ck.sh

Query::run_graphs() {
  local src="$1"
  local out="$2/graphs"
  Query::_ensure_dir "${out}"

  Query::_write_raw_chunks \
    "${out}/raw/kg" \
    'knowledge.*graph|triple.*store|entity.*relation' \
    "${src}" "py, ruby, markdown" 10 50 \
    -n -i 'knowledge.*graph|triple.*store|entity.*relation' \
    --type py --type ruby --type markdown \
    --context 10 --max-count 50 \
    "${src}"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "knowledge graph entity relationship extraction triples ontology" \
      "${_ck_root}" >> "${out}/kg_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
