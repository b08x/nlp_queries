#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034  # definitions-only file; all constants are consumed by sourced libs/bin scripts
# lib/config.sh — Shared configuration constants for nlp_queries
#
# Source this file; do not execute directly.

# ── Gum ───────────────────────────────────────────────────────────────────────
declare -gr GUM_VERSION="0.16.0"
: "${GUM:=${HOME}/.local/bin/gum}"

# ── Terminal colors (https://github.com/muesli/termenv#color-chart) ──────────
declare -gr COLOR_WHITE=251
declare -gr COLOR_GREEN=36
declare -gr COLOR_PURPLE=212
declare -gr COLOR_YELLOW=221
declare -gr COLOR_RED=9

# ── Analysis sampling parameters ─────────────────────────────────────────────
declare -gr SAMPLE_SIZE_JSONL=50    # Max lines sampled per JSONL file
declare -gr SAMPLE_SIZE_RAW=100     # Max lines sampled per raw text file
declare -gr MIN_FILE_SIZE=100       # Bytes — ignore files smaller than this

# ── ck semantic search parameters ────────────────────────────────────────────
# Read by Query::_run_ck_semantic in lib/queries.sh.
# Override any of these before sourcing queries.sh or at runtime via env.
#
#   CK_SEARCH_TYPE  search mode: sem | regex | hybrid
#   CK_THRESHOLD    minimum relevance score (0.0–1.0); applied for sem and hybrid only
#   CK_RERANK       true → forces hybrid mode (RRF reranking) regardless of CK_SEARCH_TYPE
#   CK_TOPK         maximum results returned per ck query
: "${CK_SEARCH_TYPE:=sem}"   # sem | lex | regex | hybrid
: "${CK_THRESHOLD:=0.5}"     # 0.0–1.0; sem/lex/hybrid only (lower = broader recall)
: "${CK_RERANK:=false}"       # true → forces hybrid mode (RRF reranking)
: "${CK_TOPK:=50}"             # max results per query
: "${CK_FULL_SECTION:=true}" # true → --full-section: retrieve complete functions/classes

# ── Output directories (relative to project root) ────────────────────────────
# These are resolved at runtime by each bin/ entry point; kept here for
# documentation purposes only.
#   output/run_YYYYMMDD_HHMMSS/   — extraction runs
#   analysis/analysis_YYYYMMDD/   — analysis reports
#   logs/                         — session logs
