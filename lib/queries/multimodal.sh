#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/multimodal.sh — Query::run_multimodal
#
# Searches for vision/language model and image captioning patterns.
# Depends on: helpers.sh  ck.sh

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

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "vision language model image captioning multimodal embeddings CLIP BLIP" \
      "${_ck_root}" >> "${out}/vision_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
