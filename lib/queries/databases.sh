#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/databases.sh — Query::run_databases
#
# Searches for ORM model definitions, schema/migration patterns, SQL usage,
# and Redis access patterns.
# Keywords: model, schema, Ohm, Sequel, migrations, sql, redis
# Depends on: helpers.sh  ck.sh

Query::run_databases() {
  local src="$1"
  local out="$2/databases"
  Query::_ensure_dir "${out}"

  # Structured JSONL: ORM model class definitions (Sequel, Ohm, ActiveRecord-style)
  Query::safe_rga -i '(Sequel|Ohm|ActiveRecord)::Model|class.*<.*Model' \
    --type ruby --type py --type js --type markdown \
    "${src}" --json | \
    jq -r 'select(.type == "match") |
           select(.data != null) |
           {
             file:  (.data.path.text   // "unknown"),
             line:  (.data.line_number  // 0),
             match: (.data.lines.text   // "")
           } |
           select(.match != "")' \
    > "${out}/orm_models.jsonl"

  # Raw chunks: schema blocks, dataset/table definitions, column declarations
  Query::_write_raw_chunks \
    "${out}/raw/schema_definitions" \
    'schema|sfl|dataset|table.*(define|create|column)' \
    "${src}" "ruby, py, sql, markdown" 10 75 \
    -n -i 'schema|sfl|dataset|table.*(define|create|column)' \
    --type ruby --type py --type sql --type markdown \
    --context 10 --max-count 75 \
    "${src}"

  # Raw chunks: migration files and schema change patterns
  Query::_write_raw_chunks \
    "${out}/raw/migrations" \
    'migration|migrate|sfl|create_table|add_column|alter_table' \
    "${src}" "ruby, py, sql, markdown" 10 50 \
    -n -i 'migration|migrate|sfl|create_table|add_column|alter_table' \
    --type ruby --type py --type sql --type markdown \
    --context 10 --max-count 50 \
    "${src}"

  # Raw chunks: Redis key/value, sorted set, hash, pipeline, and expiry usage
  Query::_write_raw_chunks \
    "${out}/raw/redis" \
    'redis|hset|hget|zadd|pipeline|expire|reference|collection|list|set' \
    "${src}" "ruby, py, json, markdown" 10 50 \
    -n -i 'redis|hset|hget|zadd|pipeline|expire|reference|collection|list|set' \
    --type ruby --type py --type json --type markdown \
    --context 10 --max-count 50 \
    "${src}"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "database schema model ORM Sequel Ohm table definition column association attribute sfl systemic-functional-linguistics" \
      "${_ck_root}" >> "${out}/orm_models_semantic.jsonl"
    Query::_run_ck_semantic \
      "database migration schema change create table alter column index sfl systemic-functional-linguistics" \
      "${_ck_root}" >> "${out}/migrations_semantic.jsonl"
    Query::_run_ck_semantic \
      "Redis cache key-value pipeline expiry sorted set hash counter pub-sub collection reference set list sfl systemic-functional-linguistics" \
      "${_ck_root}" >> "${out}/redis_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
