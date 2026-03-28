#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries.sh — Namespaced rga search functions for NLP pattern extraction
#
# Each Query::run_* function accepts:
#   $1  source_dir   — directory to search
#   $2  output_base  — base output directory for this extraction run
#
# Usage:
#   source lib/queries.sh
#   Query::run_chunking     ~/my-repo  output/run_20240101_120000/my-repo

set -euo pipefail
IFS=$'\n\t'

# ── Internals ─────────────────────────────────────────────────────────────────

Query::_ensure_dir() {
  mkdir -p "$1"
}

# Query::safe_rga — rga exits 1 when no matches are found; treat that as
# success (zero results) rather than a script error.
Query::safe_rga() {
  rga \
    --ignore-file="${HOME}/.gitignore" \
    --hidden \
    --rga-accurate \
    --rga-adapters='poppler,pandoc' \
    -j 4 \
    "$@" || [[ $? -eq 1 ]]
}

# ── 1. Chunking ───────────────────────────────────────────────────────────────

Query::run_chunking() {
  local src="$1"
  local out="$2/chunking"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'chunk.*strateg|semantic.*split|text.*segment' \
    --type markdown --type pdf --type ruby --type typescript --type json \
    "${src}" --json | \
    jq -r 'select(type == "object") |
           select(.type == "match") |
           select(.data != null) |
           {
             file:  (.data.path.text        // "unknown"),
             line:  (.data.line_number       // 0),
             match: (.data.lines.text        // "")
           } |
           select(.match != "")' \
    > "${out}/strategies.jsonl"

  Query::safe_rga -i 'token.*window|max.*token' \
    --type py --type ruby --type json --type markdown \
    "${src}" --json | \
    jq -r 'select(.type == "match") |
           select(.data.lines.text != null) |
           {
             source:  .data.path.text,
             content: .data.lines.text
           }' \
    > "${out}/token_configs.jsonl"

  Query::safe_rga -i '(recursive|hierarch|tree).{0,25}(chunk|split)' \
    --type markdown --type py --type ruby \
    --context 4 --max-count 75 \
    "${src}" > "${out}/hierarchical_raw.txt"
}

# ── 2. Embedding ──────────────────────────────────────────────────────────────

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
             match_text:  .data.lines.text
           } |
           select(.match_text != null)' \
    > "${out}/embedding_configs.jsonl"

  Query::safe_rga '\b(384|768|1024|1536|3072|4096)\b.*dim' \
    --type py --type ruby --type json \
    --context 2 --max-count 50 \
    "${src}" > "${out}/dimensions_raw.txt"

  Query::safe_rga 'pgvector|vector.*search' \
    --type ruby --type py --type markdown \
    "${src}" --json | \
    jq -r 'select(.type == "match") |
           {
             file:    .data.path.text,
             line:    .data.line_number,
             context: .data.lines.text
           } |
           select(.file != null)' \
    > "${out}/vector_dbs.jsonl"
}

# ── 3. Preprocessing ──────────────────────────────────────────────────────────

Query::run_preprocessing() {
  local src="$1"
  local out="$2/preprocessing"
  Query::_ensure_dir "${out}"

  Query::safe_rga 'def (clean|normalize|preprocess|sanitize)' \
    --type ruby --type py --type markdown --type pdf \
    --context 8 --max-count 100 \
    "${src}" > "${out}/methods_raw.txt"

  Query::safe_rga '(spacy|nltk|tiktoken|sentencepiece|bpe)' \
    --type py --type ruby --type json --type markdown \
    --context 3 \
    "${src}" > "${out}/tokenizers_raw.txt"
}

# ── 4. Parsers ────────────────────────────────────────────────────────────────

Query::run_parsers() {
  local src="$1"
  local out="$2/parsers"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'markdown.*(split|chunk|section|header)' \
    --type ruby --type py --type js --type markdown \
    --context 10 --max-count 75 \
    "${src}" > "${out}/markdown_splitters_raw.txt"
}

# ── 5. Pipelines ──────────────────────────────────────────────────────────────

Query::run_pipelines() {
  local src="$1"
  local out="$2/pipelines"
  Query::_ensure_dir "${out}"

  Query::safe_rga 'class \w*Pipeline|def.*pipeline' \
    --type ruby --type py --type markdown \
    --context 20 --max-count 50 \
    "${src}" > "${out}/architectures_raw.txt"
}

# ── 6. Models ─────────────────────────────────────────────────────────────────

Query::run_models() {
  local src="$1"
  local out="$2/models"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'localhost|127\.0\.0\.1|local.*model|ollama|lm studio' \
    --type py --type ruby --type json --type markdown \
    --context 4 \
    "${src}" > "${out}/local_inference_raw.txt"

  Query::safe_rga -i 'api.*key|endpoint|openai|anthropic|together' \
    --type py --type ruby --type yaml --type markdown \
    --context 3 \
    "${src}" > "${out}/api_inference_raw.txt"
}

# ── 7. Search ─────────────────────────────────────────────────────────────────

Query::run_search() {
  local src="$1"
  local out="$2/search"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'hybrid.*search|reciprocal.*rank|rrf|fusion' \
    --type py --type ruby --type markdown \
    --context 8 --max-count 50 \
    "${src}" > "${out}/hybrid_patterns_raw.txt"
}

# ── 8. Configs ────────────────────────────────────────────────────────────────

Query::run_configs() {
  local src="$1"
  local out="$2/config"
  Query::_ensure_dir "${out}"

  Query::safe_rga 'context.*(window|size|length)|max.*(token|length|context)' \
    --type json --type yaml --type py --type markdown \
    --context 3 --max-count 75 \
    "${src}" > "${out}/context_windows_raw.txt"
}

# ── 9. Graphs ─────────────────────────────────────────────────────────────────

Query::run_graphs() {
  local src="$1"
  local out="$2/graphs"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'knowledge.*graph|triple.*store|entity.*relation' \
    --type py --type ruby --type markdown \
    --context 8 --max-count 50 \
    "${src}" > "${out}/kg_raw.txt"
}

# ── 10. Multi-Modal ───────────────────────────────────────────────────────────

Query::run_multimodal() {
  local src="$1"
  local out="$2/multimodal"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'clip|blip|llava|vision.*model|image.*caption' \
    --type py --type markdown \
    --context 8 --max-count 50 \
    "${src}" > "${out}/vision_raw.txt"
}
