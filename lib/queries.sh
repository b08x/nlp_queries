#!/usr/bin/env bash

# queries.sh
# Contains the rga/jq logic adapted for ripgrep compatibility.
# Functions accept ($1: source_dir, $2: output_base_dir)

ensure_dir() {
    mkdir -p "$1"
}

# safe_rga wrapper: ripgrep/rga returns 1 if no matches are found.
# We want to treat 1 as "success with 0 results" rather than an error.
safe_rga() {
    # Run rga and allow exit code 0 (matches) or 1 (no matches)
    rga --ignore-file='/var/home/b08x/.gitignore' --hidden --rga-accurate --rga-adapters='poppler,pandoc' -j 4 "$@" || [ $? -eq 1 ]
}

# --- 1. Chunking ---
run_chunking_queries() {
    local src="$1"
    local out="$2/chunking"
    ensure_dir "$out"

    # 1.1 Basic Strategy
    safe_rga -i 'chunk.*strateg|semantic.*split|text.*segment' \
        --type markdown --type pdf --type ruby --type typescript --type json\
        "$src" \
        --json | \
        jq -r 'select(type == "object") | 
             select(.type == "match") |
             select(.data != null) |
             {
               file: (.data.path.text // "unknown"),
               line: (.data.line_number // 0),
               match: (.data.lines.text // "")
             } | 
             select(.match != "")' \
        > "$out/strategies.jsonl"

    # 1.2 Token Configs
    safe_rga -i 'token.*window|max.*token' \
        --type py --type ruby --type json --type markdown \
        "$src" \
        --json | \
        jq -r 'select(.type == "match") |
             select(.data.lines.text != null) |
             {
               source: .data.path.text,
               content: .data.lines.text
             }' \
        > "$out/token_configs.jsonl"
    
    # 1.3 Hierarchical
    safe_rga -i '(recursive|hierarch|tree).{0,25}(chunk|split)' \
        --type markdown --type py --type ruby \
        --context 4 \
        --max-count 75 \
        "$src" > "$out/hierarchical_raw.txt"
}

# --- 2. Embedding ---
run_embedding_queries() {
    local src="$1"
    local out="$2/embedding"
    ensure_dir "$out"

    safe_rga 'informers|sentence-transformers|model.*embed' \
        --type json --type yaml --type markdown --type ruby \
        "$src" \
        --json | \
        jq -r 'select(.type == "match") |
             select(.data != null) |
             {
               config_file: .data.path.text,
               match_text: .data.lines.text
             } |
             select(.match_text != null)' \
        > "$out/embedding_configs.jsonl"

    safe_rga '\b(384|768|1024|1536|3072|4096)\b.*dim' \
        --type py --type ruby --type json \
        --context 2 \
        --max-count 50 \
        "$src" > "$out/dimensions_raw.txt"

    safe_rga 'pgvector|vector.*search' \
        --type ruby --type py --type markdown \
        "$src" \
        --json | \
        jq -r 'select(.type == "match") |
             {
               file: .data.path.text,
               line: .data.line_number,
               context: .data.lines.text
             } |
             select(.file != null)' \
        > "$out/vector_dbs.jsonl"
}

# --- 3. Preprocessing ---
run_preprocessing_queries() {
    local src="$1"
    local out="$2/preprocessing"
    ensure_dir "$out"

    safe_rga 'def (clean|normalize|preprocess|sanitize)' \
        --type ruby --type py --type markdown --type pdf \
        --context 8 \
        --max-count 100 \
        "$src" > "$out/methods_raw.txt"

    safe_rga '(spacy|nltk|tiktoken|sentencepiece|bpe)' \
        --type py --type ruby --type json --type markdown \
        --context 3 \
        "$src" > "$out/tokenizers_raw.txt"
}

# --- 4. Parsers ---
run_parser_queries() {
    local src="$1"
    local out="$2/parsers"
    ensure_dir "$out"

    safe_rga -i 'markdown.*(split|chunk|section|header)' \
        --type ruby --type py --type js --type markdown \
        --context 10 \
        --max-count 75 \
        "$src" > "$out/markdown_splitters_raw.txt"
}

# --- 5. Pipelines ---
run_pipeline_queries() {
    local src="$1"
    local out="$2/pipelines"
    ensure_dir "$out"

    safe_rga 'class \w*Pipeline|def.*pipeline' \
        --type ruby --type py --type markdown \
        --context 20 \
        --max-count 50 \
        "$src" > "$out/architectures_raw.txt"
}

# --- 6. Models ---
run_model_queries() {
    local src="$1"
    local out="$2/models"
    ensure_dir "$out"

    safe_rga -i 'localhost|127\.0\.0\.1|local.*model|ollama|lm studio' \
        --type py --type ruby --type json --type markdown \
        --context 4 \
        "$src" > "$out/local_inference_raw.txt"

    safe_rga -i 'api.*key|endpoint|openai|anthropic|together' \
        --type py --type ruby --type yaml --type markdown \
        --context 3 \
        "$src" > "$out/api_inference_raw.txt"
}

# --- 7. Search ---
run_search_queries() {
    local src="$1"
    local out="$2/search"
    ensure_dir "$out"

    safe_rga -i 'hybrid.*search|reciprocal.*rank|rrf|fusion' \
        --type py --type ruby --type markdown \
        --context 8 \
        --max-count 50 \
        "$src" > "$out/hybrid_patterns_raw.txt"
}

# --- 8. Configs ---
run_config_queries() {
    local src="$1"
    local out="$2/config"
    ensure_dir "$out"

    safe_rga 'context.*(window|size|length)|max.*(token|length|context)' \
        --type json --type yaml --type py --type markdown \
        --context 3 \
        --max-count 75 \
        "$src" > "$out/context_windows_raw.txt"
}

# --- 9. Graphs ---
run_graph_queries() {
    local src="$1"
    local out="$2/graphs"
    ensure_dir "$out"

    safe_rga -i 'knowledge.*graph|triple.*store|entity.*relation' \
        --type py --type ruby --type markdown \
        --context 8 \
        --max-count 50 \
        "$src" > "$out/kg_raw.txt"
}

# --- 10. Multi-Modal ---
run_multimodal_queries() {
    local src="$1"
    local out="$2/multimodal"
    ensure_dir "$out"

    safe_rga -i 'clip|blip|llava|vision.*model|image.*caption' \
        --type py --type markdown \
        --context 8 \
        --max-count 50 \
        "$src" > "$out/vision_raw.txt"
}