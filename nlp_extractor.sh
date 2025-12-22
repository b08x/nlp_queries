#!/usr/bin/env bash

# nlp_extractor.sh
# Interactive CLI for NLP Strategy Extraction using Gum

set -e

# --- Configuration ---
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${CURRENT_DIR}/lib"
OUTPUT_BASE="${CURRENT_DIR}/output"

# Source dependencies
if [ -f "${LIB_DIR}/gum_wrapper.sh" ]; then
    source "${LIB_DIR}/gum_wrapper.sh"
else
    echo "Error: ${LIB_DIR}/gum_wrapper.sh not found."
    exit 1
fi

if [ -f "${LIB_DIR}/queries.sh" ]; then
    source "${LIB_DIR}/queries.sh"
else
    echo "Error: ${LIB_DIR}/queries.sh not found."
    exit 1
fi

check_dependencies() {
    local missing_deps=()
    ! command -v rga &> /dev/null && missing_deps+=("ripgrep-all (rga)")
    ! command -v jq &> /dev/null && missing_deps+=("jq")

    if [ ${#missing_deps[@]} -ne 0 ]; then
        gum_style --foreground 196 "Error: Missing dependencies."
        for dep in "${missing_deps[@]}"; do gum_style --foreground 252 " - $dep"; done
        exit 1
    fi
}

execute_extraction() {
    local title="$1"
    local func_name="$2"
    local source_dir="$3"
    local output_dir="$4"
    local log_err="${output_dir}/${func_name}_errors.log"
    
    export LIB_DIR
    
    # We wrap the call in '|| true' within the logic of queries.sh (safe_rga)
    # But here we still check for actual system errors (exit codes > 1)
    if ! gum_spin --title "$title" -- \
        bash -c '
            set -e
            source "$LIB_DIR/queries.sh"
            "$1" "$2" "$3" 2>"$4"
        ' -- "$func_name" "$source_dir" "$output_dir" "$log_err"; then
        
        # Check if the log has actual errors (not just empty matches)
        if [ -s "$log_err" ]; then
            gum_fail "Error in: $title"
            gum_style --foreground 203 "$(cat "$log_err")"
            return 1
        fi
    fi
    return 0
}

# --- Main ---
gum_init
check_dependencies
clear

gum_style --border double --margin "1 2" --padding "1 2" --border-foreground 212 \
    "NLP Strategy Extraction" "  Pattern Discovery & Agent Tagging"

gum_title "Configuration"

INPUT_PATHS=()
if [ $# -gt 0 ]; then
    for arg in "$@"; do
        if [ -d "$arg" ]; then
            INPUT_PATHS+=("$(realpath "$arg")")
        else
            gum_warn "Not a directory, skipping: $arg"
        fi
    done
fi

if [ ${#INPUT_PATHS[@]} -eq 0 ]; then
    DEFAULT_SOURCE="$HOME/Notebook"
    SOURCE_DIR=$(gum_input --value "$DEFAULT_SOURCE" --placeholder "Source dir...")
    [ ! -d "$SOURCE_DIR" ] && { gum_fail "Not a directory: $SOURCE_DIR"; exit 1; }
    INPUT_PATHS+=("$(realpath "$SOURCE_DIR")")
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_OUTPUT="${OUTPUT_BASE}/run_${TIMESTAMP}"
mkdir -p "$SESSION_OUTPUT"

gum_info "Results: $SESSION_OUTPUT"
sleep 0.2
! gum_confirm "Start Extraction?" && { gum_warn "Aborted."; exit 0; }

gum_title "Select Strategies"
OPTIONS=("1. Chunking" "2. Embedding" "3. Preprocessing" "4. Parsers" "5. Pipelines" "6. Models" "7. Search" "8. Configs" "9. Graphs" "10. Multi-Modal")
SELECTED=$(printf "%s\n" "${OPTIONS[@]}" | gum choose --no-limit --height 15)
[ -z "$SELECTED" ] && { gum_warn "Nothing selected."; exit 0; }

gum_title "Processing"
for SOURCE_DIR in "${INPUT_PATHS[@]}"; do
    FOLDER_NAME=$(basename "$SOURCE_DIR")
    # Handling root or '.' gracefully
    [ "$FOLDER_NAME" == "." ] || [ -z "$FOLDER_NAME" ] && FOLDER_NAME="root"
    
    CURRENT_SESSION_OUTPUT="${SESSION_OUTPUT}/${FOLDER_NAME}"
    mkdir -p "$CURRENT_SESSION_OUTPUT"
    
    gum_info "Processing Source: $SOURCE_DIR"
    gum_info "Results: $CURRENT_SESSION_OUTPUT"

    while read -r category; do
        [ -z "$category" ] && continue
        case "$category" in
            *"1. Chunking"*) execute_extraction "Chunking" "run_chunking_queries" "$SOURCE_DIR" "$CURRENT_SESSION_OUTPUT" || true ;;
            *"2. Embedding"*) execute_extraction "Embedding" "run_embedding_queries" "$SOURCE_DIR" "$CURRENT_SESSION_OUTPUT" || true ;;
            *"3. Preprocessing"*) execute_extraction "Preprocessing" "run_preprocessing_queries" "$SOURCE_DIR" "$CURRENT_SESSION_OUTPUT" || true ;;
            *"4. Parsers"*) execute_extraction "Parsers" "run_parser_queries" "$SOURCE_DIR" "$CURRENT_SESSION_OUTPUT" || true ;;
            *"5. Pipelines"*) execute_extraction "Pipelines" "run_pipeline_queries" "$SOURCE_DIR" "$CURRENT_SESSION_OUTPUT" || true ;;
            *"6. Models"*) execute_extraction "Models" "run_model_queries" "$SOURCE_DIR" "$CURRENT_SESSION_OUTPUT" || true ;;
            *"7. Search"*) execute_extraction "Search" "run_search_queries" "$SOURCE_DIR" "$CURRENT_SESSION_OUTPUT" || true ;;
            *"8. Configs"*) execute_extraction "Configs" "run_config_queries" "$SOURCE_DIR" "$CURRENT_SESSION_OUTPUT" || true ;;
            *"9. Graphs"*) execute_extraction "Graphs" "run_graph_queries" "$SOURCE_DIR" "$CURRENT_SESSION_OUTPUT" || true ;;
            *"10. Multi-Modal"*) execute_extraction "Multi-Modal" "run_multimodal_queries" "$SOURCE_DIR" "$CURRENT_SESSION_OUTPUT" || true ;;
        esac
    done <<< "$SELECTED"
done

gum_title "Finished"
FILE_COUNT=$(find "$SESSION_OUTPUT" -type f \( -name "*.jsonl" -o -name "*.txt" \) | wc -l)
gum_style --border rounded --border-foreground 36 --padding "1 2" \
    "Summary" "Files: $FILE_COUNT" "Location: $SESSION_OUTPUT"

[ "$(gum choose "Explore" "Exit")" = "Explore" ] && ls -R "$SESSION_OUTPUT" | gum pager