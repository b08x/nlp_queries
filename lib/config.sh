#!/usr/bin/env bash
# shellcheck shell=bash
# lib/config.sh — Shared configuration constants for nlp_queries
#
# Source this file; do not execute directly.

# ── Gum ───────────────────────────────────────────────────────────────────────
declare -g GUM_VERSION="0.16.0"
: "${GUM:=${HOME}/.local/bin/gum}"

# ── Terminal colors (https://github.com/muesli/termenv#color-chart) ──────────
declare -g COLOR_WHITE=251
declare -g COLOR_GREEN=36
declare -g COLOR_PURPLE=212
declare -g COLOR_YELLOW=221
declare -g COLOR_RED=9

# ── Analysis sampling parameters ─────────────────────────────────────────────
declare -g SAMPLE_SIZE_JSONL=50    # Max lines sampled per JSONL file
declare -g SAMPLE_SIZE_RAW=100     # Max lines sampled per raw text file
declare -g MIN_FILE_SIZE=100       # Bytes — ignore files smaller than this

# ── ck semantic search parameters ────────────────────────────────────────────
# Read by Query::_run_ck_semantic in lib/queries.sh.
# Override any of these before sourcing queries.sh or at runtime via env.
#
#   CK_SEARCH_TYPE  search mode: sem | regex | hybrid
#   CK_THRESHOLD    minimum relevance score (0.0–1.0); applied for sem and hybrid only
#   CK_RERANK       true → forces hybrid mode (RRF reranking) regardless of CK_SEARCH_TYPE
#   CK_TOPK         maximum results returned per ck query
declare -g CK_SEARCH_TYPE="sem"   # sem | lex | regex | hybrid
declare -g CK_THRESHOLD="0.5"     # 0.0–1.0; sem/lex/hybrid only (lower = broader recall)
declare -g CK_RERANK="false"       # true → forces hybrid mode (RRF reranking)
declare -g CK_TOPK=50             # max results per query
declare -g CK_FULL_SECTION="true" # true → --full-section: retrieve complete functions/classes

# ── Output directories (relative to project root) ────────────────────────────
# These are resolved at runtime by each bin/ entry point; kept here for
# documentation purposes only.
#   output/run_YYYYMMDD_HHMMSS/   — extraction runs
#   analysis/analysis_YYYYMMDD/   — analysis reports
#   logs/                         — session logs
