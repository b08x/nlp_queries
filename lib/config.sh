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

# ── Output directories (relative to project root) ────────────────────────────
# These are resolved at runtime by each bin/ entry point; kept here for
# documentation purposes only.
#   output/run_YYYYMMDD_HHMMSS/   — extraction runs
#   analysis/analysis_YYYYMMDD/   — analysis reports
#   logs/                         — session logs
