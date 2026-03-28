#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/models.sh — Query::run_models
#
# Searches for local inference (Ollama, LM Studio) and remote API configurations.
# Depends on: helpers.sh  ck.sh

Query::run_models() {
  local src="$1"
  local out="$2/models"
  Query::_ensure_dir "${out}"

  Query::_write_raw_chunks \
    "${out}/raw/local_inference" \
    'localhost|127\.0\.0\.1|local.*model|ollama|lm studio' \
    "${src}" "py, ruby, json, markdown" 10 '~' \
    -n -i 'localhost|127\.0\.0\.1|local.*model|ollama|lm studio' \
    --type py --type ruby --type json --type markdown \
    --context 10 \
    "${src}"

  Query::_write_raw_chunks \
    "${out}/raw/api_inference" \
    'api.*key|endpoint|openai|anthropic|together' \
    "${src}" "py, ruby, yaml, markdown" 10 '~' \
    -n -i 'api.*key|endpoint|openai|anthropic|together' \
    --type py --type ruby --type yaml --type markdown \
    --context 10 \
    "${src}"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "local model inference ollama LM Studio self-hosted LLM configuration" \
      "${_ck_root}" >> "${out}/local_inference_semantic.jsonl"
    Query::_run_ck_semantic \
      "API endpoint configuration OpenAI Anthropic remote model integration" \
      "${_ck_root}" >> "${out}/api_inference_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
