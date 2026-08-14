#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/multimodal.sh — Query::run_multimodal
#
# Searches for vision/language model and image captioning patterns.
# Depends on: helpers.sh  qmd.sh

Query::run_multimodal() {
  local src="$1"
  local out="$2/multimodal"
  Query::_ensure_dir "${out}"

  Query::_write_raw_chunks \
    "${out}/raw/vision" \
    'clip|blip|llava|vision.*model|image.*caption' \
    "${src}" "py, markdown" 10 50 \
    -n -i 'clip|blip|llava|vision.*model|image.*caption' \
    --type py --type markdown --type ruby \
    --context 10 --max-count 50 \
    "${src}"

  local _collection
  while IFS= read -r _collection; do
    Query::_run_qmd_semantic \
      "vision language model image captioning multimodal embeddings CLIP BLIP" \
      "${_collection}" >> "${out}/vision_semantic.jsonl"
  done < <(Query::qmd_find_collections "${src}")
}
