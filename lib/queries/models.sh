#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/models.sh — Query::run_models
#
# Searches for local inference (Ollama, LM Studio) and remote API configurations.
# Depends on: helpers.sh  qmd.sh

Query::run_models() {
  local src="$1"
  local out="$2/models"
  Query::_ensure_dir "${out}"

  Query::_write_raw_chunks \
    "${out}/raw/local_inference" \
    'embedding.*model|ollama' \
    "${src}" "py, ruby, json, markdown" 10 '~' \
    -n -i 'embedding.*model|ollama' \
    --type py --type ruby --type json --type markdown \
    --context 10 \
    "${src}"

  Query::_write_raw_chunks \
    "${out}/raw/api_inference" \
    'api.*key|endpoint|gemini|anthropic|openrouter|mistral' \
    "${src}" "py, ruby, yaml, markdown" 10 '~' \
    -n -i 'api.*key|endpoint|gemini|anthropic|openrouter|mistral' \
    --type py --type ruby --type yaml --type markdown \
    --context 10 \
    "${src}"

  local _collection
  while IFS= read -r _collection; do
    Query::_run_qmd_semantic \
      "model inference ollama self-hosted LLM configuration" \
      "${_collection}" >> "${out}/local_inference_semantic.jsonl"
    Query::_run_qmd_semantic \
      "API endpoint configuration gemini anthropic openrouter mistral remote model integration" \
      "${_collection}" >> "${out}/api_inference_semantic.jsonl"
  done < <(Query::qmd_find_collections "${src}")
}
