#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/embedding.sh — Query::run_embedding
#
# Searches for embedding model configs, vector dimensions, and vector DB usage.
# Depends on: helpers.sh  ck.sh

Query::run_embedding() {
  local src="$1"
  local out="$2/embedding"
  Query::_ensure_dir "${out}"

  Query::safe_rga 'informers|sentence-transformers|model.*embed' \
    --type json --type yaml --type markdown --type ruby \
    "${src}" --json | \
    jq -r 'select(.type == "match") |
           select(.data != null) |
           {
             config_file: .data.path.text,
             line:        (.data.line_number // 0),
             match_text:  .data.lines.text
           } |
           select(.match_text != null)' \
    > "${out}/embedding_configs.jsonl"

  Query::_write_raw_chunks \
    "${out}/raw/dimensions" \
    '\b(384|768|1024|1536|3072|4096)\b.*dim' \
    "${src}" "py, ruby, json" 10 50 \
    -n '\b(384|768|1024|1536|3072|4096)\b.*dim' \
    --type py --type ruby --type json \
    --context 10 --max-count 50 \
    "${src}"

  Query::safe_rga 'pgvector|vector.*search' \
    --type ruby --type py --type markdown \
    "${src}" --json | \
    jq -r 'select(.type == "match") |
           {
             file:    .data.path.text,
             line:    (.data.line_number // 0),
             context: .data.lines.text
           } |
           select(.file != null)' \
    > "${out}/vector_dbs.jsonl"

  Query::_write_raw_chunks \
    "${out}/raw/vector_dbs" \
    'pgvector|vector.*search' \
    "${src}" "ruby, py, markdown" 10 50 \
    -n 'pgvector|vector.*search' \
    --type ruby --type py --type markdown \
    --context 10 --max-count 50 \
    "${src}"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "embedding model configuration dimensions vector similarity" \
      "${_ck_root}" >> "${out}/embedding_configs_semantic.jsonl"
    Query::_run_ck_semantic \
      "vector database pgvector similarity search index embeddings" \
      "${_ck_root}" >> "${out}/vector_dbs_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
