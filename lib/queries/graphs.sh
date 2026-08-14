#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/graphs.sh — Query::run_graphs
#
# Searches for knowledge graph, triple store, and entity-relation patterns.
# Depends on: helpers.sh  qmd.sh

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

  local _collection
  while IFS= read -r _collection; do
    Query::_run_qmd_semantic \
      "knowledge graph entity relationship extraction triples ontology" \
      "${_collection}" >> "${out}/kg_semantic.jsonl"
  done < <(Query::qmd_find_collections "${src}")
}
