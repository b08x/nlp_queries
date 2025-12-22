#!/usr/bin/env bash

# diagnose_extraction.sh
# Diagnostic utility for extraction run structure analysis

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output"

echo "═══════════════════════════════════════"
echo "  Extraction Run Structure Diagnostics"
echo "═══════════════════════════════════════"
echo ""

# Check if output directory exists
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "ERROR: Output directory not found: $OUTPUT_DIR"
    exit 1
fi

echo "Output Directory: $OUTPUT_DIR"
echo ""

# Find all run directories
echo "▸ Discovering Extraction Runs..."
runs=$(find "$OUTPUT_DIR" -maxdepth 1 -type d -name "run_*" | sort -r)

if [ -z "$runs" ]; then
    echo "  No extraction runs found"
    exit 0
fi

run_count=$(echo "$runs" | wc -l)
echo "  Found: $run_count run(s)"
echo ""

# Analyze each run
for run_dir in $runs; do
    run_name=$(basename "$run_dir")
    echo "━━━ $run_name ━━━"
    
    # Count source directories
    src_count=$(find "$run_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    echo "  Source Directories: $src_count"
    
    if [ "$src_count" -eq 0 ]; then
        echo "  ⚠ No source directories found"
        echo ""
        echo "  Directory contents:"
        ls -lah "$run_dir" | sed 's/^/    /'
        echo ""
        continue
    fi
    
    # List source directories with their category counts
    while IFS= read -r src_dir; do
        src_name=$(basename "$src_dir")
        cat_count=$(find "$src_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        file_count=$(find "$src_dir" -type f \( -name "*.jsonl" -o -name "*_raw.txt" \) 2>/dev/null | wc -l)
        
        echo "  → $src_name"
        echo "     Categories: $cat_count | Files: $file_count"
        
        # Show category breakdown if files exist
        if [ "$file_count" -gt 0 ]; then
            for category in chunking embedding preprocessing parsers pipelines models search config graphs multimodal; do
                cat_path="$src_dir/$category"
                if [ -d "$cat_path" ]; then
                    cat_files=$(find "$cat_path" -type f 2>/dev/null | wc -l)
                    if [ "$cat_files" -gt 0 ]; then
                        echo "       • $category: $cat_files files"
                    fi
                fi
            done
        else
            echo "       ⚠ No extraction files found"
            echo "       Directory structure:"
            find "$src_dir" -maxdepth 2 -type d -exec basename {} \; | sed 's/^/         - /'
        fi
        echo ""
    done < <(find "$run_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
    
    # Overall statistics for this run
    total_files=$(find "$run_dir" -type f \( -name "*.jsonl" -o -name "*_raw.txt" \) 2>/dev/null | wc -l)
    total_size=$(du -sh "$run_dir" 2>/dev/null | awk '{print $1}')
    
    echo "  Summary: $total_files files | $total_size total"
    echo ""
done

echo "═══════════════════════════════════════"
echo ""

# Provide recommendations
echo "Recommendations:"
echo ""
if [ "$run_count" -gt 0 ]; then
    latest_run=$(echo "$runs" | head -1)
    latest_files=$(find "$latest_run" -type f \( -name "*.jsonl" -o -name "*_raw.txt" \) 2>/dev/null | wc -l)
    
    if [ "$latest_files" -eq 0 ]; then
        echo "  ⚠ Latest run contains no extraction files"
        echo "    - Verify extraction queries are finding matches"
        echo "    - Check extraction logs for errors"
        echo "    - Ensure source directories contain searchable content"
    else
        echo "  ✓ Latest run appears valid with $latest_files files"
        echo "    - Ready for analysis with nlp_strategy_analyzer.sh"
    fi
else
    echo "  ⚠ No extraction runs found"
    echo "    - Run nlp_extractor.sh first to generate extraction data"
fi

echo ""
