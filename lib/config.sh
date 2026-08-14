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

# ── qmd semantic search parameters ────────────────────────────────────────────
# Read by Query::_run_qmd_semantic in lib/queries.sh.
# Override any of these before sourcing queries.sh or at runtime via env.
#
#   QMD_SEARCH_MODE  search mode: query | vsearch | search  (default: query = hybrid)
#   QMD_MIN_SCORE    minimum relevance score (0.0–1.0); lower = broader recall
#   QMD_TOPK         maximum results returned per qmd query
#   QMD_FULL         true → show full document content
: "${QMD_SEARCH_MODE:=query}"  # query (hybrid) | vsearch (vector) | search (BM25)
: "${QMD_MIN_SCORE:=0.3}"      # 0.0–1.0; lower = broader recall
: "${QMD_TOPK:=50}"             # max results per query
: "${QMD_FULL:=true}"           # true → --full: retrieve complete document

# ── Output directories (relative to project root) ────────────────────────────
# These are resolved at runtime by each bin/ entry point; kept here for
# documentation purposes only.
#   output/run_YYYYMMDD_HHMMSS/   — extraction runs
#   analysis/analysis_YYYYMMDD/   — analysis reports
#   logs/                         — session logs
