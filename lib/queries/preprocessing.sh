#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/preprocessing.sh — Query::run_preprocessing
#
# Searches for text cleaning/normalization methods and tokenizer usage.
# Depends on: helpers.sh  qmd.sh

Query::run_preprocessing() {
  local src="$1"
  local out="$2/preprocessing"
  Query::_ensure_dir "${out}"

  Query::_write_raw_chunks \
    "${out}/raw/methods" \
    'def (clean|normalize|preprocess|sanitize)' \
    "${src}" "ruby, py, markdown, pdf" 10 100 \
    -n 'def (clean|normalize|preprocess|sanitize)' \
    --type ruby --type py --type markdown --type pdf \
    --context 10 --max-count 100 \
    "${src}"

  Query::_write_raw_chunks \
    "${out}/raw/tokenizers" \
    '(spacy|segmenter|tokenizer|lingua|bpe)' \
    "${src}" "py, ruby, json, markdown" 10 '~' \
    -n '(spacy|segmenter|tokenizer|lingua|bpe)' \
    --type py --type ruby --type json --type markdown \
    --context 10 \
    "${src}"

  local _collection
  while IFS= read -r _collection; do
    Query::_run_qmd_semantic \
      "text cleaning normalization preprocessing pipeline sanitization" \
      "${_collection}" >> "${out}/methods_semantic.jsonl"
    Query::_run_qmd_semantic \
      "tokenizer BPE segmenter NLP tokenization lingua" \
      "${_collection}" >> "${out}/tokenizers_semantic.jsonl"
  done < <(Query::qmd_find_collections "${src}")
}
