# nlp_queries

> Bash CLI for discovering and cataloging NLP/ML implementation patterns across codebases

[![zread](https://img.shields.io/badge/Ask_Zread-_.svg?style=flat&color=00b0aa&labelColor=000000&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTQuOTYxNTYgMS42MDAxSDIuMjQxNTZDMS44ODgxIDEuNjAwMSAxLjYwMTU2IDEuODg2NjQgMS42MDE1NiAyLjI0MDFWNC45NjAxQzEuNjAxNTYgNS4zMTM1NiAxLjg4ODEgNS42MDAxIDIuMjQxNTYgNS42MDAxSDQuOTYxNTZDNS4zMTUwMiA1LjYwMDEgNS42MDE1NiA1LjMxMzU2IDUuNjAxNTYgNC45NjAxVjIuMjQwMUM1LjYwMTU2IDEuODg2NjQgNS4zMTUwMiAxLjYwMDEgNC45NjE1NiAxLjYwMDFaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik00Ljk2MTU2IDEwLjM5OTlIMi4yNDE1NkMxLjg4ODEgMTAuMzk5OSAxLjYwMTU2IDEwLjY4NjQgMS42MDE1NiAxMS4wMzk5VjEzLjc1OTlDMS42MDE1NiAxNC4xMTM0IDEuODg4MSAxNC4zOTk5IDIuMjQxNTYgMTQuMzk5OUg0Ljk2MTU2QzUuMzE1MDIgMTQuMzk5OSA1LjYwMTU2IDE0LjExMzQgNS42MDE1NiAxMy43NTk5VjExLjAzOTlDNS42MDE1NiAxMC42ODY0IDUuMzE1MDIgMTAuMzk5OSA0Ljk2MTU2IDEwLjM5OTlaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik0xMy43NTg0IDEuNjAwMUgxMS4wMzg0QzEwLjY4NSAxLjYwMDEgMTAuMzk4NCAxLjg4NjY0IDEwLjM5ODQgMi4yNDAxVjQuOTYwMUMxMC4zOTg0IDUuMzEzNTYgMTAuNjg1IDUuNjAwMSAxMS4wMzg0IDUuNjAwMUgxMy43NTg0QzE0LjExMTkgNS42MDAxIDE0LjM5ODQgNS4zMTM1NiAxNC4zOTg0IDQuOTYwMVYyLjI0MDFDMTQuMzk4NCAxLjg4NjY0IDE0LjExMTkgMS42MDAxIDEzLjc1ODQgMS42MDAxWiIgZmlsbD0iI2ZmZiIvPgo8cGF0aCBkPSJNNCAxMkwxMiA0TDQgMTJaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik00IDEyTDEyIDQiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLXdpZHRoPSIxLjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K&logoColor=ffffff)](https://zread.ai/b08x/nlp_queries)

[![Shell](https://img.shields.io/badge/shell-bash-89e051.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Searches source code, configs, and documents with `rga` (ripgrep-all) across 10 pattern categories. Writes structured JSONL records and context-rich Markdown chunks with YAML frontmatter. The 5-stage analysis pipeline distills those into frequency tables, method catalogs, and strategy recommendations.

---

## Features

- **Multi-format search** — `rga` reaches inside PDFs, Office docs, and archives alongside source files, so patterns in documentation surface alongside their implementations
- **10 extraction categories** — chunking, embedding, preprocessing, parsers, pipelines, models, search, configs, graphs, and multimodal; run one or all in a single session
- **Context-preserving output** — each match group becomes a standalone `chunk_NNNN.md` file with YAML frontmatter (file, line, query, timestamp) and N lines of surrounding context
- **5-stage analysis pipeline** — discovery → inventory → stratified sampling → pattern extraction → strategy formulation; outputs `inventory.md`, `patterns.md`, and `strategy.md`
- **Interactive TUI** — Gum-based menus, spinners, and confirmations; auto-downloads the `gum` binary on first run
- **Multi-source support** — pass multiple directories as CLI arguments to extract and compare patterns across repositories in one session
- **Timestamped sessions** — every run writes to `output/run_YYYYMMDD_HHMMSS/` so successive extractions never overwrite each other

---

## Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| `rga` (ripgrep-all) | Multi-format search engine | `cargo install ripgrep-all` |
| `jq` | JSON processing | `sudo dnf install jq` / `sudo apt install jq` |
| `fd` | Fast file finder (replaces `find`) | `cargo install fd-find` |
| `sd` | In-place text replacement (replaces `sed`) | `cargo install sd` |
| `choose` | Field selection (replaces `awk` field ops) | `cargo install choose` |
| `gum` | Terminal UI | Auto-downloaded to `~/.local/bin/` on first run |

---

## Installation

```bash
git clone https://github.com/b08x/nlp_queries.git
cd nlp_queries
chmod +x bin/*
```

Install Rust-based tools in one pass:

```bash
cargo install ripgrep-all fd-find sd choose
```

`jq` via system package manager:

```bash
# Fedora/RHEL
sudo dnf install jq

# Debian/Ubuntu
sudo apt install jq
```

`gum` downloads automatically on first run. To pin a custom binary:

```bash
GUM=/usr/local/bin/gum bin/nlpq.sh
```

---

## Usage

### Full pipeline (recommended)

```bash
bin/nlpq.sh
```

Prompts for pipeline mode, output directory, source directory, and category selection. Select **Full Pipeline** to run extract → diagnose → analyze in sequence.

Pass source directories as arguments to skip the source directory prompt:

```bash
bin/nlpq.sh ~/Projects/ml-codebase ~/Research/nlp-experiments
```

Custom output directory:

```bash
NLPQ_OUTPUT_BASE=~/my_results bin/nlpq.sh
```

### Individual stages

```bash
bin/nlp-extract                     # Interactive extraction
bin/nlp-extract ~/repo1 ~/repo2     # Extraction, multiple sources
bin/nlp-diag                        # Validate most-recent extraction run
bin/nlp-analyze                     # Analysis on most-recent extraction run
```

### Pipeline modes

| Mode | Command | Description |
|------|---------|-------------|
| Full Pipeline | `bin/nlpq.sh` | Extract → diagnose → analyze |
| Extract Only | `bin/nlp-extract` | Run query categories, write output |
| Analyze Only | `bin/nlp-analyze` | Process existing extraction run |
| Diagnose Only | `bin/nlp-diag` | Validate run structure and file counts |

---

## Output Structure

```
output/run_YYYYMMDD_HHMMSS/
└── <source_dir>/
    ├── chunking/
    │   ├── strategies.jsonl          # Structured: {file, line, match}
    │   └── hierarchical/
    │       ├── chunk_0000.md         # YAML frontmatter + context lines
    │       └── chunk_0001.md
    ├── embedding/
    ├── preprocessing/
    ├── parsers/
    ├── pipelines/
    ├── models/
    ├── search/
    ├── config/
    ├── graphs/
    └── multimodal/

analysis/analysis_YYYYMMDD_HHMMSS/
├── inventory.md      # File counts, sizes, distribution by category
├── patterns.md       # Method signatures, term frequencies, dimension values
├── strategy.md       # Compilation recommendations, quality metrics
└── samples/          # Stratified samples (50 JSONL lines / 100 raw lines per file)

logs/session_YYYYMMDD_HHMMSS.log
```

**JSONL format:**

```json
{"file": "path/to/file.py", "line": 42, "match": "chunk_strategy = 'semantic'"}
```

**Chunk file format** (`chunk_NNNN.md`):

```markdown
---
query: "chunk.*strateg"
source_file: "text_splitter.py"
line: 42
source: "/home/user/Projects/ml-codebase"
types: [py, ruby, json]
context_lines: 4
max_count: 75
generated_at: "2026-03-28T20:19:30Z"
---

40-    # Configure chunking strategy
41-    strategy = config.get("strategy", "fixed")
42:    chunk_strategy = "semantic_split"
43-    max_tokens = 512
44-    overlap = 128
```

---

## Extraction Categories

| # | Category | Extracts |
|---|----------|----------|
| 1 | **Chunking** | Splitting strategies, token windows, hierarchical logic |
| 2 | **Embedding** | Model references, vector dimensions (384/768/1024/…), vector DB integrations |
| 3 | **Preprocessing** | Text cleaning, tokenizer implementations, stop word/stemming patterns |
| 4 | **Parsers** | Markdown splitters, section/heading parsers, document structure analyzers |
| 5 | **Pipelines** | Pipeline class definitions, multi-stage processing flows |
| 6 | **Models** | Local inference (Ollama, LM Studio), API integrations (OpenAI, Anthropic) |
| 7 | **Search** | Hybrid search, Reciprocal Rank Fusion, fusion algorithm patterns |
| 8 | **Configs** | Context windows, token limits, model configuration parameters |
| 9 | **Graphs** | Knowledge graph implementations, entity-relation extraction |
| 10 | **Multimodal** | Vision models (CLIP, BLIP, LLaVA), image captioning, multi-modal fusion |

---

## Architecture

```
bin/
├── nlpq.sh        # Pipeline orchestrator — mode selection, env export
├── nlp-extract    # Extraction: category selection → Query::run_* → output/
├── nlp-analyze    # Analysis: 5-stage pipeline → analysis/
└── nlp-diag       # Diagnostics: run structure validation, file counts

lib/
├── config.sh      # Constants: GUM_VERSION, color codes, sampling params
├── log.sh         # Log::info/warn/error/success/stage — stderr + log file
├── gum.sh         # Gum::* wrappers, auto-download, EXIT/ERR traps
├── queries.sh     # Dispatcher — sources lib/queries/*.sh, routes run_*
└── queries/
    ├── helpers.sh        # Query::safe_rga, Query::_ensure_dir, Query::_write_raw_chunks
    ├── chunking.sh
    ├── embedding.sh
    ├── preprocessing.sh
    ├── parsers.sh
    ├── pipelines.sh
    ├── models.sh
    ├── search.sh
    ├── configs.sh
    ├── graphs.sh
    ├── multimodal.sh
    ├── databases.sh
    └── ck.sh             # Semantic search via ck (optional)
```

### Library loading

Every bin script sources all libraries and initialises before doing any work:

```bash
for _lib in config log gum queries; do
  source "${LIB_DIR}/${_lib}.sh"
done
Log::setup "${SCRIPT_DIR}/../logs"
Gum::init
Gum::install_traps
```

### Subshell execution

`bin/nlp-extract` runs each category inside a `bash -c` subshell under `Gum::spin`. The subshell re-sources `lib/queries.sh` via exported `LIB_DIR`:

```bash
export LIB_DIR
Gum::spin --title "Chunking" -- bash -c '
  source "${LIB_DIR}/queries.sh"
  "$1" "$2" "$3" 2>"$4"
' -- "Query::run_chunking" "$src" "$out" "$err_log"
```

### `Query::safe_rga` defaults

Applied to every search call:

```
--ignore-file="${HOME}/.gitignore"
--hidden
--rga-accurate
--rga-adapters='poppler,pandoc'
-j 4
```

---

## Development

### Adding an extraction category

1. **Create `lib/queries/<name>.sh`** with a `Query::run_<name>` function:

```bash
Query::run_custom() {
  local src="$1"
  local out="$2/custom"
  Query::_ensure_dir "${out}"

  # Structured JSONL output
  Query::safe_rga -i 'your.*pattern' \
    --type py --type ruby \
    "${src}" --json | \
    jq -r 'select(.type == "match") |
           {file: .data.path.text, match: .data.lines.text}' \
    > "${out}/custom_results.jsonl"

  # Context-rich chunk output (optional)
  Query::_write_raw_chunks \
    "${out}/raw" "your.*pattern" "${src}" "py, ruby" 4 75 \
    -i 'your.*pattern' --type py --type ruby "${src}"
}
```

2. **Register in `bin/nlp-extract`** — add to the `options` array and the `case` dispatch:

```bash
*"11. Custom"*) _run_category "Custom" "Query::run_custom" "${src_dir}" "${src_output}" || true ;;
```

### Pattern testing

```bash
# Test a regex before integrating
rga -i 'chunk.*strateg' --type py ~/test/source --json | jq .

# Test a Query:: function directly
source lib/config.sh && source lib/queries.sh
Query::run_chunking ~/source /tmp/test_out

# View session log
tail -f logs/session_*.log
```

### Key constraints

- Always use `Query::safe_rga` — bare `rga` exits 1 on no matches, which aborts under `set -e`
- Always call `Query::_ensure_dir` before writing to any output subdirectory
- Always include `--type` filters — omitting them searches binaries and inflates runtime
- Never use `echo`/`printf` for user-facing output in bin scripts — use `Gum::info`, `Gum::warn`, `Gum::fail`

---

## Troubleshooting

**`rga: command not found`**

```bash
cargo install ripgrep-all
```

**Empty results for all categories**

```bash
# Verify rga finds anything in the source dir
rga 'def ' "$SOURCE_DIR" --type py

# Run diagnostics on the extraction run
bin/nlp-diag
```

**Analysis fails with "No extraction runs found"**

```bash
ls -la output/       # Verify runs exist
bin/nlp-extract      # Run extraction first
```

**Stratified sampling produces empty files**

Files under 100 bytes are skipped by the sampler. Check extraction output size:

```bash
fd -t f -e jsonl -e md output/ -x wc -l
```

---

## License

MIT — see [LICENSE](LICENSE).

---

## Acknowledgments

- [ripgrep-all](https://github.com/phiresky/ripgrep-all) — multi-format search
- [Gum](https://github.com/charmbracelet/gum) — terminal UI toolkit
- [fd](https://github.com/sharkdp/fd), [sd](https://github.com/chmln/sd), [choose](https://github.com/theryangeary/choose) — modern Unix CLI tools
- [jq](https://jqlang.github.io/jq/) — JSON processing
