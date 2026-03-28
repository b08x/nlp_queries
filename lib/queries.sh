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

# ── ck semantic search helpers ────────────────────────────────────────────────

# Query::ck_find_roots — print src if it contains a .ck index, otherwise nothing.
# Yields src itself so _ck_root always matches the provided input folder arg.
Query::ck_find_roots() {
  local src="$1"
  [[ -d "${src}/.ck" ]] && echo "${src}"
}

# Query::safe_ck — ck exits 1 when no matches are found; treat that as success.
# Silently skips if ck is not installed.
Query::safe_ck() {
  command -v ck &>/dev/null || return 0
  ck "$@" || [[ $? -eq 1 ]]
}

# Query::_run_ck_semantic — run one ck query and write JSONL to stdout.
# Callers redirect stdout to the desired output file (>> file.jsonl).
#
# $1  query    — natural language (sem/hybrid/lex) or regex search phrase
# $2  ck_root  — directory containing a .ck index
#
# CK_SEARCH_TYPE   sem | lex | regex | hybrid  (default: sem)
# CK_THRESHOLD     0.0–1.0                      (default: 0.4, sem/lex/hybrid only)
# CK_RERANK        true | false                 (default: true; true → forces hybrid/RRF)
# CK_TOPK          integer                      (default: 50)
# CK_FULL_SECTION  true | false                 (default: true; returns complete functions)
Query::_run_ck_semantic() {
  local query="$1"
  local ck_root="$2"

  local _search_type="${CK_SEARCH_TYPE:-sem}"
  local _threshold="${CK_THRESHOLD:-0.5}"
  local _rerank="${CK_RERANK:-false}"
  local _topk="${CK_TOPK:-50}"
  local _full_section="${CK_FULL_SECTION:-true}"

  # Reranking via RRF requires hybrid mode; upgrade silently if requested
  [[ "${_rerank}" == "true" && "${_search_type}" != "hybrid" ]] && _search_type="hybrid"

  local -a ck_flags=(--jsonl --topk "${_topk}")
  case "${_search_type}" in
    sem)    ck_flags+=(--sem    --threshold "${_threshold}") ;;
    lex)    ck_flags+=(--lex    --threshold "${_threshold}") ;;
    hybrid) ck_flags+=(--hybrid --threshold "${_threshold}") ;;
    regex)  ck_flags+=(--regex) ;;
    *)      ck_flags+=(--sem    --threshold "${_threshold}") ;;
  esac
  [[ "${_full_section}" == "true" ]] && ck_flags+=(--full-section)

  # ck info lines (model, config) go to stderr; redirect so only JSONL hits stdout.
  # Real field names in ck v0.7+: .path (not .file), .snippet (not .preview).
  # Fall back to span description when snippet is absent.
  Query::safe_ck "${ck_flags[@]}" "${query}" "${ck_root}" 2>/dev/null | \
    jq -r 'select(type == "object") | select(.path != null) | {
      file:  .path,
      line:  (.span.line_start // 0),
      score: (.score   // 0),
      match: (.snippet // ("lines \(.span.line_start // 0)-\(.span.line_end // 0)"))
    }'
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
    --context 10 --max-count 75 \
    "${src}" > "${out}/hierarchical_raw.txt"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "text chunking strategies recursive splitting semantic segmentation" \
      "${_ck_root}" >> "${out}/strategies_semantic.jsonl"
    Query::_run_ck_semantic \
      "token window size maximum token limits configuration" \
      "${_ck_root}" >> "${out}/token_configs_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
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
    --context 10 --max-count 50 \
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

  Query::safe_rga 'pgvector|vector.*search' \
    --type ruby --type py --type markdown \
    --context 10 --max-count 50 \
    "${src}" > "${out}/vector_dbs_raw.txt"

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

# ── 3. Preprocessing ──────────────────────────────────────────────────────────

Query::run_preprocessing() {
  local src="$1"
  local out="$2/preprocessing"
  Query::_ensure_dir "${out}"

  Query::safe_rga 'def (clean|normalize|preprocess|sanitize)' \
    --type ruby --type py --type markdown --type pdf \
    --context 10 --max-count 100 \
    "${src}" > "${out}/methods_raw.txt"

  Query::safe_rga '(spacy|nltk|tiktoken|sentencepiece|bpe)' \
    --type py --type ruby --type json --type markdown \
    --context 10 \
    "${src}" > "${out}/tokenizers_raw.txt"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "text cleaning normalization preprocessing pipeline sanitization" \
      "${_ck_root}" >> "${out}/methods_semantic.jsonl"
    Query::_run_ck_semantic \
      "tokenizer BPE sentencepiece tiktoken NLP tokenization" \
      "${_ck_root}" >> "${out}/tokenizers_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
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

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "markdown document parsing splitting by headers sections structure" \
      "${_ck_root}" >> "${out}/markdown_splitters_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
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

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "RAG pipeline architecture stages ingestion retrieval augmented generation" \
      "${_ck_root}" >> "${out}/architectures_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}

# ── 6. Models ─────────────────────────────────────────────────────────────────

Query::run_models() {
  local src="$1"
  local out="$2/models"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'localhost|127\.0\.0\.1|local.*model|ollama|lm studio' \
    --type py --type ruby --type json --type markdown \
    --context 10 \
    "${src}" > "${out}/local_inference_raw.txt"

  Query::safe_rga -i 'api.*key|endpoint|openai|anthropic|together' \
    --type py --type ruby --type yaml --type markdown \
    --context 10 \
    "${src}" > "${out}/api_inference_raw.txt"

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

# ── 7. Search ─────────────────────────────────────────────────────────────────

Query::run_search() {
  local src="$1"
  local out="$2/search"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'hybrid.*search|reciprocal.*rank|rrf|fusion' \
    --type py --type ruby --type markdown \
    --context 10 --max-count 50 \
    "${src}" > "${out}/hybrid_patterns_raw.txt"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "hybrid search reciprocal rank fusion retrieval augmented dense sparse" \
      "${_ck_root}" >> "${out}/hybrid_patterns_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}

# ── 8. Configs ────────────────────────────────────────────────────────────────

Query::run_configs() {
  local src="$1"
  local out="$2/config"
  Query::_ensure_dir "${out}"

  Query::safe_rga 'context.*(window|size|length)|max.*(token|length|context)' \
    --type json --type yaml --type py --type markdown \
    --context 10 --max-count 75 \
    "${src}" > "${out}/context_windows_raw.txt"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "context window size token limit configuration parameters settings" \
      "${_ck_root}" >> "${out}/context_windows_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}

# ── 9. Graphs ─────────────────────────────────────────────────────────────────

Query::run_graphs() {
  local src="$1"
  local out="$2/graphs"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'knowledge.*graph|triple.*store|entity.*relation' \
    --type py --type ruby --type markdown \
    --context 10 --max-count 50 \
    "${src}" > "${out}/kg_raw.txt"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "knowledge graph entity relationship extraction triples ontology" \
      "${_ck_root}" >> "${out}/kg_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}

# ── 10. Multi-Modal ───────────────────────────────────────────────────────────

Query::run_multimodal() {
  local src="$1"
  local out="$2/multimodal"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'clip|blip|llava|vision.*model|image.*caption' \
    --type py --type markdown \
    --context 10 --max-count 50 \
    "${src}" > "${out}/vision_raw.txt"

  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "vision language model image captioning multimodal embeddings CLIP BLIP" \
      "${_ck_root}" >> "${out}/vision_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
