# LIB DIRECTORY

Shared libraries sourced by main scripts: extraction query engine + UI framework.

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add extraction function | `queries.sh` | Follow pattern: `run_<category>_queries()` |
| Modify regex patterns | `queries.sh` | Lines 18-210, 10 category functions |
| Customize UI colors | `gum_wrapper.sh` | Lines 30-35, color constants |
| Add UI component | `gum_wrapper.sh` | Lines 230-238, wrapper functions |
| Modify error traps | `gum_wrapper.sh` | Lines 52-97, trap_error/trap_exit |
| Change gum download | `gum_wrapper.sh` | Lines 103-198, gum_init() |

## EXTRACTION FUNCTIONS (queries.sh)

**10 Category Functions:**

- `run_chunking_queries` - Semantic split, token windows, hierarchical patterns
- `run_embedding_queries` - Models, dimensions, vector DBs
- `run_preprocessing_queries` - Clean/normalize functions, tokenizers
- `run_parser_queries` - Markdown splitters
- `run_pipeline_queries` - Pipeline classes/functions
- `run_model_queries` - Local/API inference
- `run_search_queries` - Hybrid search, RRF
- `run_config_queries` - Context windows, token limits
- `run_graph_queries` - Knowledge graphs
- `run_multimodal_queries` - Vision models

**Function Signature:**

```bash
run_<category>_queries() {
    local src="$1"          # Source directory to search
    local out="$2/<category>"  # Output subdirectory
    ensure_dir "$out"       # Create output dir
    
    # Execute safe_rga searches with patterns
}
```

**Output Conventions:**

- JSONL files: `<name>.jsonl` - machine-readable, processed with jq
- Raw text: `<name>_raw.txt` - human-readable, includes context lines

## UI FRAMEWORK (gum_wrapper.sh)

**Trap Functions:**

- `trap_error()` - Captures failures → writes to `$ERROR_MSG` file
- `trap_exit()` - Reads error file → displays message → cleanup
- `trap_gum_exit()` - Ctrl+C handler (exit 130)

**Color Scheme:**

```bash
COLOR_PURPLE=212  # Titles, prompts, interactive elements
COLOR_GREEN=36    # Success, summaries, property values
COLOR_YELLOW=221  # Warnings, info messages
COLOR_RED=9       # Errors, failures
COLOR_WHITE=251   # Standard text
```

**Wrapper Functions:**

```bash
gum_title()    # Bold purple "+" prefix
gum_info()     # Green "•" prefix
gum_warn()     # Yellow "•" prefix
gum_fail()     # Red "•" prefix
gum_confirm()  # Purple prompt
gum_input()    # Purple header/prompt
gum_choose()   # Purple cursor
gum_filter()   # Purple header
```

## CONVENTIONS

**Adding New Extraction Function:**

1. Define `run_<name>_queries()` in queries.sh
2. Accept `$1` (source dir), `$2` (output base)
3. Call `ensure_dir "$out/<category>"`
4. Use `safe_rga` (NOT raw rga) with `--type` filters
5. Pipe JSON output through jq OR redirect raw to .txt
6. Register in `nlp_extractor.sh` OPTIONS array + case statement

**Regex Pattern Design:**

- Case-insensitive: `-i` flag
- Flexible spacing: `.*` between terms
- Alternatives: `(term1|term2|term3)`
- Context: `--context N` for surrounding lines
- Limit: `--max-count 75` to prevent overwhelming output

**Safe rga Usage:**

```bash
safe_rga 'pattern' \
    --type py --type ruby \
    "$src" \
    --json | jq -r 'select(.type == "match") | ...'
```

## ANTI-PATTERNS (LIB)

- **Never** call raw `rga` in extraction functions - use `safe_rga` wrapper
- **Never** hardcode color values in new functions - use `COLOR_*` constants
- **Never** call gum binary directly - use wrapper functions (gum_info, gum_confirm, etc.)
- **Never** skip `ensure_dir` before writing to output subdirectory
- **Never** forget `--type` filters in rga searches (searches everything, very slow)
- **Never** output extraction results to root of `$2` - always use subdirectory
