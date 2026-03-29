#!/usr/bin/env bash
# shellcheck shell=bash
# bin/nlpq.sh — Primary entrypoint: full NLP extraction + analysis pipeline
#
# Stages (in order):
#   1. Extract  — pattern discovery via nlp-extract
#   2. Diagnose — validate extraction run via nlp-diag
#   3. Analyze  — 5-stage analysis pipeline via nlp-analyze
#
# Usage:
#   bin/nlpq.sh                        # interactive mode selection
#   bin/nlpq.sh ~/repo1 ~/repo2        # full pipeline with source directories
#   bin/nlpq.sh --extract-only [dirs]  # extraction stage only
#   bin/nlpq.sh --analyze-only         # analysis on most recent extraction
#   bin/nlpq.sh --diag-only            # diagnostic scan only

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/../lib"

# ── Source libraries ──────────────────────────────────────────────────────────

for _lib in config log gum; do
  if [[ ! -f "${LIB_DIR}/${_lib}.sh" ]]; then
    echo "Error: ${LIB_DIR}/${_lib}.sh not found" >&2
    exit 1
  fi
  # shellcheck source=/dev/null
  source "${LIB_DIR}/${_lib}.sh"
done
unset _lib

# ── Startup ───────────────────────────────────────────────────────────────────

Log::setup "${SCRIPT_DIR}/../logs"
Gum::init
Gum::install_traps

# ── Stage runners ─────────────────────────────────────────────────────────────

_run_extract() {
  Log::stage "Stage 1 of 3: Extraction"
  "${SCRIPT_DIR}/nlp-extract" "$@"
}

_run_diag() {
  Log::stage "Stage 2 of 3: Diagnostics"
  "${SCRIPT_DIR}/nlp-diag"
}

_run_analyze() {
  Log::stage "Stage 3 of 3: Analysis"
  "${SCRIPT_DIR}/nlp-analyze"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
  local mode="prompt"
  local -a src_args=()

  # Parse flags and source directory arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --extract-only) mode="extract" ; shift ;;
      --analyze-only) mode="analyze" ; shift ;;
      --diag-only)    mode="diag"    ; shift ;;
      -*)
        Gum::warn "Unknown flag: $1"
        shift
        ;;
      *)
        src_args+=("$1")
        mode="full"   # source dirs imply full pipeline
        shift
        ;;
    esac
  done

  Gum::style \
    --border double --margin "1 2" --padding "1 2" \
    --border-foreground "${COLOR_PURPLE}" \
    "NLP Query Pipeline" \
    "  Extraction  ·  Diagnostics  ·  Analysis"

  # Interactive mode selection when no flags or source dirs given
  if [[ "${mode}" == "prompt" ]]; then
    local chosen
    chosen="$(Gum::choose \
      "Full Pipeline  (Extract → Diagnose → Analyze)" \
      "Extract Only" \
      "Analyze Only" \
      "Diagnose Only")"

    case "${chosen}" in
      "Full Pipeline"*) mode="full"    ;;
      "Extract Only")   mode="extract" ;;
      "Analyze Only")   mode="analyze" ;;
      "Diagnose Only")  mode="diag"    ;;
      *)
        Gum::warn "No mode selected."
        exit 0
        ;;
    esac

    # Prompt for output directory (applies to all stages)
    Gum::title "Output Directory"
    local ts chosen_output
    ts="$(date +%Y%m%d_%H%M%S)"
    chosen_output="$(Gum::input \
      --value "${HOME}/nlpq_${ts}" \
      --placeholder "Directory for all output files...")"
    [[ -z "${chosen_output}" ]] && { Gum::warn "No output directory provided."; exit 0; }
    export NLPQ_OUTPUT_BASE="${chosen_output}"
    export NLPQ_ANALYSIS_OUTPUT="${chosen_output}/analysis"

    # Prompt for source directories only when extraction is part of the run
    if [[ "${mode}" == "full" || "${mode}" == "extract" ]]; then
      Gum::title "Source Directories"
      local -a chosen_dirs
      mapfile -t chosen_dirs < <(
        fd . "${HOME}" -t d -d 2 | Gum::_run filter --no-limit --placeholder "Select source directories..."
      )
      if [[ ${#chosen_dirs[@]} -eq 0 ]]; then
        Gum::fail "No directories selected."
        exit 1
      fi
      for dir in "${chosen_dirs[@]}"; do
        [[ -d "${dir}" ]] && src_args+=("$(realpath "${dir}")")
      done
    fi
  fi

  case "${mode}" in
    full)
      _run_extract "${src_args[@]+"${src_args[@]}"}"
      _run_diag
      _run_analyze
      ;;
    extract)
      _run_extract "${src_args[@]+"${src_args[@]}"}"
      ;;
    analyze)
      _run_analyze
      ;;
    diag)
      _run_diag
      ;;
  esac

  Log::success "Pipeline complete."
}

main "$@"
