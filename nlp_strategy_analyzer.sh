#!/usr/bin/env bash

# nlp_strategy_analyzer.sh
# Multi-Stage Sampling & Strategy Formulation Pipeline

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRACTION_BASE="${SCRIPT_DIR}/output"
ANALYSIS_OUTPUT="${SCRIPT_DIR}/analysis"

# Sampling parameters
SAMPLE_SIZE_JSONL=50      # Lines per JSONL file
SAMPLE_SIZE_RAW=100       # Lines per raw text file
MIN_FILE_SIZE=100         # Bytes - ignore smaller files

# --- Utilities ---
log_stage() {
    echo -e "\n━━━ $1 ━━━" >&2
}

log_info() {
    echo "  ▸ $1" >&2
}

log_success() {
    echo "  ✓ $1" >&2
}

# --- Stage 1: Discovery ---
discover_extraction_runs() {
    log_stage "Stage 1: Extraction Run Discovery"
    
    log_info "Scanning: $EXTRACTION_BASE"
    
    # Locate all run_* directories in output folder
    local runs=()
    while IFS= read -r -d '' run_dir; do
        runs+=("$run_dir")
    done < <(find "$EXTRACTION_BASE" -maxdepth 1 -type d -name "run_*" -print0 2>/dev/null)
    
    if [ ${#runs[@]} -eq 0 ]; then
        echo "Error: No extraction runs found in $EXTRACTION_BASE"
        echo "Expected directory structure: output/run_TIMESTAMP/"
        exit 1
    fi
    
    log_info "Discovered ${#runs[@]} extraction run(s):"
    
    # Display all runs with timestamps
    for run in "${runs[@]}"; do
        local run_name=$(basename "$run")
        local source_count=$(find "$run" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        log_info "  • $run_name ($source_count source directories)"
    done
    
    # Select most recent run (lexicographically sorted by timestamp)
    SELECTED_RUN=$(printf '%s\n' "${runs[@]}" | sort -r | head -1)
    
    echo "" >&2
    log_success "Selected: $(basename "$SELECTED_RUN")"
    
    # Display source directories within selected run
    log_info "Source directories in selected run:"
    find "$SELECTED_RUN" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | \
        sort | while read -r src_dir; do
        local category_count=$(find "$SELECTED_RUN/$src_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        log_info "  • $src_dir ($category_count categories)"
    done
    
    # Return clean path (trim any whitespace)
    echo "$SELECTED_RUN" | tr -d '\n\r' | xargs
}

# --- Stage 2: Inventory Analysis ---
analyze_inventory() {
    local run_dir="$1"
    local inventory_file="$2"
    
    log_stage "Stage 2: Content Inventory Analysis"
    
    # Validation: Check if run directory exists and has content
    if [ ! -d "$run_dir" ]; then
        log_info "ERROR: Run directory does not exist: $run_dir"
        return 1
    fi
    
    local src_count=$(find "$run_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    log_info "Found $src_count source directories in: $(basename "$run_dir")"
    
    if [ "$src_count" -eq 0 ]; then
        log_info "WARNING: No source directories found in run directory"
        log_info "Run directory contents:"
        ls -la "$run_dir" >&2
    fi
    
    {
        echo "# Extraction Inventory"
        echo "Run: $(basename "$run_dir")"
        echo "Timestamp: $(date)"
        echo ""
        
        # Analyze by source directory
        echo "## Source Directory Analysis"
        echo ""
        
        # More robust directory iteration
        local found_sources=false
        while IFS= read -r src_dir; do
            [ ! -d "$src_dir" ] && continue
            found_sources=true
            
            local src_name=$(basename "$src_dir")
            echo "### $src_name"
            echo ""
            
            local has_categories=false
            for category in chunking embedding preprocessing parsers pipelines models search config graphs multimodal; do
                local cat_path="${src_dir}/${category}"
                if [ -d "$cat_path" ]; then
                    has_categories=true
                    local file_count=$(find "$cat_path" -type f 2>/dev/null | wc -l)
                    local jsonl_count=$(find "$cat_path" -type f -name "*.jsonl" 2>/dev/null | wc -l)
                    local raw_count=$(find "$cat_path" -type f -name "*_raw.txt" 2>/dev/null | wc -l)
                    local size=$(du -sh "$cat_path" 2>/dev/null | awk '{print $1}')
                    
                    if [ "$file_count" -gt 0 ]; then
                        printf "%-20s Files: %2d (jsonl: %2d, raw: %2d)   Size: %s\n" \
                            "$category:" "$file_count" "$jsonl_count" "$raw_count" "${size:-0}"
                    fi
                fi
            done
            
            if [ "$has_categories" = false ]; then
                echo "*No category directories found*"
                echo ""
                echo "Directory structure:"
                find "$src_dir" -maxdepth 2 -type d -exec basename {} \; | sed 's/^/  - /'
            fi
            
            echo ""
        done < <(find "$run_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
        
        if [ "$found_sources" = false ]; then
            echo "*No source directories found in extraction run*"
            echo ""
            echo "Run directory structure:"
            find "$run_dir" -maxdepth 2 | sed 's/^/  /'
            echo ""
        fi
        
        # Overall summary
        echo "## Overall Summary"
        echo ""
        
        local total_files=$(find "$run_dir" -type f \( -name "*.jsonl" -o -name "*_raw.txt" \) 2>/dev/null | wc -l)
        local total_jsonl=$(find "$run_dir" -type f -name "*.jsonl" 2>/dev/null | wc -l)
        local total_raw=$(find "$run_dir" -type f -name "*_raw.txt" 2>/dev/null | wc -l)
        local total_size=$(du -sh "$run_dir" 2>/dev/null | awk '{print $1}')
        
        echo "- Total Files: $total_files"
        echo "- Structured Data (JSONL): $total_jsonl"
        echo "- Raw Text Extracts: $total_raw"
        echo "- Total Size: ${total_size:-unknown}"
        
        if [ "$total_files" -eq 0 ]; then
            echo ""
            echo "**WARNING**: No extraction files found. This could indicate:"
            echo "- Extraction queries returned no matches"
            echo "- Incorrect directory structure"
            echo "- Extraction process failed silently"
        fi
        echo ""
        
    } | tee "$inventory_file"
    
    log_success "Inventory saved to: $inventory_file"
}

# --- Stage 3: Stratified Sampling ---
perform_sampling() {
    local run_dir="$1"
    local sample_dir="$2"
    
    log_stage "Stage 3: Stratified Sampling"
    
    mkdir -p "$sample_dir"
    
    local categories=(chunking embedding preprocessing parsers pipelines models search config graphs multimodal)
    
    for category in "${categories[@]}"; do
        local cat_sample_dir="${sample_dir}/${category}"
        mkdir -p "$cat_sample_dir"
        
        # Find all files in this category across all source directories
        while IFS= read -r file; do
            [ ! -f "$file" ] && continue
            [ "$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)" -lt "$MIN_FILE_SIZE" ] && continue
            
            local filename=$(basename "$file")
            local output_file="${cat_sample_dir}/${filename%.jsonl}_sample.txt"
            
            if [[ "$file" == *.jsonl ]]; then
                # Sample JSONL: extract random lines, parse with jq
                shuf -n "$SAMPLE_SIZE_JSONL" "$file" 2>/dev/null | \
                    jq -r 'select(.file != null and .match != null) | 
                           "FILE: \(.file)\nMATCH: \(.match)\n---"' \
                    > "$output_file" 2>/dev/null || true
            else
                # Sample raw text: extract context windows
                shuf -n "$SAMPLE_SIZE_RAW" "$file" 2>/dev/null > "$output_file" || true
            fi
            
            if [ -s "$output_file" ]; then
                log_info "Sampled: ${category}/${filename}"
            else
                rm -f "$output_file"
            fi
            
        done < <(find "${run_dir}"/*/"${category}" -type f \( -name "*.jsonl" -o -name "*_raw.txt" \) 2>/dev/null)
    done
    
    log_success "Samples saved to: $sample_dir"
}

# --- Stage 4: Pattern Extraction ---
extract_patterns() {
    local sample_dir="$1"
    local pattern_file="$2"
    
    log_stage "Stage 4: Pattern & Method Signature Extraction"
    
    {
        echo "# NLP Pattern Analysis"
        echo "Generated: $(date)"
        echo ""
        
        echo "## Method Signatures"
        echo ""
        
        # Extract Ruby/Python method definitions
        echo "### Function Definitions"
        rg -N --no-heading '^\s*(def|class|function)\s+\w+' "$sample_dir" \
            --max-count 30 2>/dev/null | \
            sort -u | \
            sed 's/^/  - /' || echo "  (none found)"
        
        echo ""
        echo "## Common Patterns"
        echo ""
        
        # Extract common technical terms
        echo "### Chunking Strategies"
        rg -oN -i '\b(chunk|split|segment|window|overlap|stride)\w*' \
            "${sample_dir}/chunking" 2>/dev/null | \
            sort | uniq -c | sort -rn | head -10 | \
            awk '{printf "  %3d × %s\n", $1, $2}' || echo "  (none found)"
        
        echo ""
        echo "### Model References"
        rg -oN '\b(transformer|bert|gpt|llama|embedding|sentence-\w+)' \
            "${sample_dir}/embedding" "${sample_dir}/models" 2>/dev/null | \
            sort | uniq -c | sort -rn | head -10 | \
            awk '{printf "  %3d × %s\n", $1, $2}' || echo "  (none found)"
        
        echo ""
        echo "### Vector Operations"
        rg -oN -i '\b(cosine|euclidean|similarity|distance|vector|embedding)\w*' \
            "${sample_dir}/search" "${sample_dir}/embedding" 2>/dev/null | \
            sort | uniq -c | sort -rn | head -10 | \
            awk '{printf "  %3d × %s\n", $1, $2}' || echo "  (none found)"
        
        echo ""
        echo "## Configuration Patterns"
        echo ""
        
        # Extract numeric configurations
        echo "### Dimension Values"
        rg -oN '\b(384|768|1024|1536|3072|4096)\b' "$sample_dir" 2>/dev/null | \
            sort | uniq -c | sort -rn | \
            awk '{printf "  %3d × %s dimensions\n", $1, $2}' || echo "  (none found)"
        
        echo ""
        echo "### Parameter Settings"
        rg -oN '\b(top_k|max_tokens|chunk_size|overlap|threshold|temperature)\s*[:=]\s*\d+' \
            "${sample_dir}/config" 2>/dev/null | \
            sort | uniq -c | sort -rn | head -8 | \
            sed 's/^/  /' || echo "  (none found)"
        
    } | tee "$pattern_file"
    
    log_success "Patterns saved to: $pattern_file"
}

# --- Stage 5: Strategy Formulation ---
formulate_strategies() {
    local pattern_file="$1"
    local inventory_file="$2"
    local strategy_file="$3"
    
    log_stage "Stage 5: Compilation Strategy Formulation"
    
    {
        echo "# NLP Processing Strategy Synthesis"
        echo "Generated: $(date)"
        echo ""
        
        echo "## Recommended Compilation Approach"
        echo ""
        
        echo "### Stage 1: Taxonomy Construction"
        echo "- **Objective**: Create hierarchical classification of discovered methods"
        echo "- **Process**:"
        echo "  1. Group by processing stage (ingestion → preprocessing → chunking → embedding → retrieval)"
        echo "  2. Categorize by technical approach (statistical, neural, hybrid)"
        echo "  3. Tag by implementation language/framework"
        echo ""
        
        echo "### Stage 2: Method Signature Extraction"
        echo "- **Objective**: Catalog reusable function signatures and class definitions"
        echo "- **Process**:"
        echo "  1. Parse function definitions with parameter types"
        echo "  2. Extract configuration schemas (YAML/JSON)"
        echo "  3. Document dependencies and imports"
        echo ""
        
        echo "### Stage 3: Pattern Consolidation"
        echo "- **Objective**: Identify recurring implementation patterns"
        echo "- **Process**:"
        echo "  1. Cluster similar chunking strategies (token-based, semantic, hybrid)"
        echo "  2. Map embedding model configurations to use cases"
        echo "  3. Document search/retrieval patterns (vector, hybrid, graph-based)"
        echo ""
        
        echo "### Stage 4: Configuration Template Generation"
        echo "- **Objective**: Create reusable configuration templates"
        echo "- **Process**:"
        echo "  1. Extract parameter distributions (chunk_size, overlap ratios)"
        echo "  2. Document model-specific settings (dimensions, distance metrics)"
        echo "  3. Catalog pipeline architectures"
        echo ""
        
        echo "## Next Steps"
        echo ""
        echo "### Immediate Actions"
        echo "1. **Deep Sampling**: Expand sampling to capture edge cases and variants"
        echo "2. **Contextual Analysis**: Extract surrounding code for implementation context"
        echo "3. **Dependency Mapping**: Build dependency graphs for method interactions"
        echo ""
        
        echo "### Medium-Term Objectives"
        echo "1. **Method Library Creation**: Compile validated methods into categorized library"
        echo "2. **Benchmark Development**: Create test cases for method comparison"
        echo "3. **Documentation Generation**: Auto-generate method documentation from samples"
        echo ""
        
        echo "## Compilation Targets"
        echo ""
        
        echo "### Primary Artifacts"
        echo "- **Method Catalog**: Searchable database of NLP processing methods"
        echo "- **Configuration Repository**: Validated parameter sets for common tasks"
        echo "- **Pattern Library**: Reusable implementation patterns with examples"
        echo "- **Decision Trees**: Guides for selecting appropriate methods by use case"
        echo ""
        
        echo "### Secondary Outputs"
        echo "- **Integration Templates**: Boilerplate for common pipeline configurations"
        echo "- **Comparison Matrices**: Feature/performance comparisons across methods"
        echo "- **Best Practice Guides**: Curated recommendations by domain"
        echo ""
        
        echo "## Quality Metrics"
        echo ""
        
        # Calculate basic metrics from inventory
        local total_methods=$(grep -c '^  - ' "$pattern_file" 2>/dev/null || echo 0)
        local unique_patterns=$(rg -N --count '\b(chunk|embed|search|parse)' "$pattern_file" 2>/dev/null | wc -l)
        
        echo "- **Methods Discovered**: $total_methods signatures"
        echo "- **Pattern Categories**: $unique_patterns distinct types"
        echo "- **Coverage Assessment**: $(cat "$inventory_file" | grep 'Total Files' | awk '{print $3}') source files analyzed"
        echo ""
        
    } | tee "$strategy_file"
    
    log_success "Strategy document saved to: $strategy_file"
}

# --- Main Execution ---
main() {
    echo "╔════════════════════════════════════════════╗" >&2
    echo "║  NLP Strategy Analysis Pipeline            ║" >&2
    echo "║  Multi-Stage Sampling & Synthesis          ║" >&2
    echo "╚════════════════════════════════════════════╝" >&2
    
    # Setup analysis workspace
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ANALYSIS_RUN="${ANALYSIS_OUTPUT}/analysis_${TIMESTAMP}"
    SAMPLE_DIR="${ANALYSIS_RUN}/samples"
    
    mkdir -p "$ANALYSIS_RUN"
    
    # Execute pipeline stages
    RUN_DIR=$(discover_extraction_runs)
    
    # Validate and sanitize returned path
    RUN_DIR=$(echo "$RUN_DIR" | xargs)  # Trim whitespace
    
    if [ -z "$RUN_DIR" ]; then
        echo "ERROR: Discovery function returned empty path" >&2
        exit 1
    fi
    
    if [ ! -d "$RUN_DIR" ]; then
        echo "ERROR: Discovered path is not a directory: '$RUN_DIR'" >&2
        echo "Path length: ${#RUN_DIR} characters" >&2
        echo "Path hex dump:" >&2
        echo "$RUN_DIR" | od -c >&2
        exit 1
    fi
    
    log_info "Validated run directory: $RUN_DIR"
    
    analyze_inventory "$RUN_DIR" "${ANALYSIS_RUN}/inventory.md"
    
    perform_sampling "$RUN_DIR" "$SAMPLE_DIR"
    
    extract_patterns "$SAMPLE_DIR" "${ANALYSIS_RUN}/patterns.md"
    
    formulate_strategies \
        "${ANALYSIS_RUN}/patterns.md" \
        "${ANALYSIS_RUN}/inventory.md" \
        "${ANALYSIS_RUN}/strategy.md"
    
    # Generate summary
    log_stage "Pipeline Complete"
    
    echo "" >&2
    echo "Analysis Results:" >&2
    echo "  Location: $ANALYSIS_RUN" >&2
    echo "" >&2
    echo "  Artifacts:" >&2
    echo "    📊 inventory.md  - Content distribution analysis" >&2
    echo "    🔍 patterns.md   - Extracted patterns and methods" >&2
    echo "    📋 strategy.md   - Compilation strategy recommendations" >&2
    echo "    📁 samples/      - Stratified sample data" >&2
    echo "" >&2
    
    # Offer to view strategy
    if command -v less &> /dev/null; then
        read -p "View strategy document? [y/N] " -n 1 -r >&2
        echo >&2
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            less "${ANALYSIS_RUN}/strategy.md"
        fi
    fi
}

main "$@"