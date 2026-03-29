# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bash-based CLI for discovering and cataloging NLP/ML implementation patterns across codebases. Uses ripgrep-all (rga) to search source code, configs, and documents; outputs structured JSONL and context-rich Markdown chunks via an interactive Gum terminal UI.

## Architecture

### Entry Points (`bin/`)

- **`bin/nlpq.sh`** — Primary entrypoint. Prompts for pipeline mode (Full / Extract / Analyze / Diagnose), exports `NLPQ_OUTPUT_BASE` and `NLPQ_ANALYSIS_OUTPUT`, then delegates to the stage scripts.
- **`bin/nlp-extract`** — Interactive extraction. Prompts for source directories and strategy categories, runs `Query::run_*` functions under `Gum::spin`, writes timestamped results to `output/run_TIMESTAMP/`.
- **`bin/nlp-analyze`** — Non-interactive 5-stage pipeline: discovery → inventory → sampling → pattern extraction → strategy formulation. Operates on the most recent `output/run_*` directory.
- **`bin/nlp-diag`** — Read-only diagnostic. Scans `output/` runs and reports file counts per category.

### Shared Libraries (`lib/`)

Each library is sourced by bin scripts; none have side effects on source.

- **`lib/config.sh`** — Declares shared constants: `GUM_VERSION`, color codes (`COLOR_PURPLE=212` etc.), sampling parameters (`SAMPLE_SIZE_JSONL`, `MIN_FILE_SIZE`). Source this first.
- **`lib/log.sh`** — `Log::setup <dir>` creates a timestamped log file. `Log::info/warn/error/success/stage` write to both stderr and the log file. `Log::file` returns the active path.
- **`lib/gum.sh`** — All Gum wrappers under `Gum::` namespace. `Gum::init` locates or downloads the binary. `Gum::install_traps` registers EXIT/ERR handlers (call once per bin script).
- **`lib/queries.sh`** — Dispatcher only. Sources all files under `lib/queries/*.sh` and exposes `Query::run_*` to callers.

### `lib/queries/` — Modular Query Engine

Each category lives in its own file. Shared internals are in `helpers.sh`:

- **`helpers.sh`** — `Query::_ensure_dir`, `Query::safe_rga` (rga wrapper that treats exit 1 as success), and `Query::_write_raw_chunks` (splits rga context output into per-match `chunk_NNNN.md` files with YAML frontmatter).
- **`chunking.sh`, `embedding.sh`, `preprocessing.sh`, `parsers.sh`, `pipelines.sh`, `models.sh`, `search.sh`, `configs.sh`, `graphs.sh`, `multimodal.sh`, `databases.sh`, `ck.sh`** — One `Query::run_<name>` function each.

### `Query::_write_raw_chunks`

Signature: `Query::_write_raw_chunks dest_dir query source types ctx maxc [rga_args…]`

Pipes `Query::safe_rga` output through awk. Each `--`-delimited match group becomes a standalone `chunk_NNNN.md` file. The awk program buffers pre-context lines in `prebuf[]` (which arrive before `sf` is known) and retroactively strips the source-file prefix once the first match line sets `sf` — this handles `--context N` output correctly for all N lines before and after a match. The `fmt_line()` helper consolidates prefix-strip + separator normalisation (`-` and `:` both become `": "`).

YAML frontmatter written per chunk:
```yaml
---
query: "chunk.*strateg"
source_file: "text_splitter.py"
line: 42
source: "/path/to/source"
types: [py, ruby]
context_lines: 4
max_count: 75
generated_at: "2026-03-28T20:19:30Z"
---
```

### Library Loading Pattern

Every bin script sources all four libraries and calls `Log::setup`, `Gum::init`, `Gum::install_traps` before doing any work:

```bash
for _lib in config log gum queries; do
  source "${LIB_DIR}/${_lib}.sh"
done
Log::setup "${SCRIPT_DIR}/../logs"
Gum::init
Gum::install_traps
```

### Subshell Execution

`bin/nlp-extract` runs each query category inside a `bash -c` subshell under `Gum::spin`. The subshell re-sources `lib/queries.sh` (exported `LIB_DIR` is how it finds the file) and calls the function by name:

```bash
export LIB_DIR
Gum::spin --title "Chunking" -- bash -c '
  source "${LIB_DIR}/queries.sh"
  "$1" "$2" "$3" 2>"$4"
' -- "Query::run_chunking" "$src" "$out" "$err_log"
```

Bash functions with `::` in their names are valid and survive this pattern.

## Commands

```bash
# Full interactive pipeline (recommended)
bin/nlpq.sh

# Multi-source extraction
bin/nlp-extract ~/repo1 ~/repo2 ~/repo3

# Analysis pipeline (processes most recent output/run_*)
bin/nlp-analyze

# Diagnostic validation
bin/nlp-diag

# Override gum binary location
GUM=/usr/bin/gum bin/nlp-extract

# Custom output directory
NLPQ_OUTPUT_BASE=~/my_results bin/nlpq.sh
```

### Dependencies

```bash
cargo install ripgrep-all fd-find sd choose   # rga, fd, sd, choose
sudo dnf install jq                           # Fedora/RHEL
sudo apt install jq                           # Ubuntu/Debian
# gum is auto-downloaded to ~/.local/bin/gum on first run
```

### Development / Testing

```bash
# Test a regex pattern before adding to a query file
rga -i 'chunk.*strateg' --type py ~/test/source --json | jq .

# Test a Query:: function directly
source lib/config.sh && source lib/queries.sh
Query::run_chunking ~/source /tmp/test_out

# View session log
tail -f logs/session_*.log

# Count result files across a run
fd -t f -e jsonl -e md . output/run_*/ | wc -l
```

## Adding New Extraction Categories

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

## Key Constraints

- **Always use `Query::safe_rga`**, never bare `rga` — exit code 1 (no matches) must not abort the script.
- **Always call `Query::_ensure_dir`** before writing to any output subdirectory.
- **Never use `echo`/`printf` for user-facing messages** in bin scripts — use `Gum::info`, `Gum::warn`, `Gum::fail`.
- **Always include `--type` filters** on rga searches — omitting them causes slow searches and false positives on binaries.
- **Use `fd` not `find`**, **`sd` not `sed`**, **`choose` not `awk '{print $N}'`** — the codebase uses modern Unix tools throughout. `awk` is retained only for formatted `printf` output (`%3d × %s`) where `choose` has no equivalent.
- **`fd` requires an explicit pattern** — `fd [opts] . /path/` uses `.` as the match-all pattern; omitting it makes `fd` treat the directory path as the pattern (which fails with a `/` warning). Extension filters (`-e`) and type filters (`-t`) do not count as patterns. Exception: `-g 'glob'` IS an explicit pattern — `fd -t d -d 1 -g 'run_*' /path/` is correct without `.`.
- **`fd --format '{/}'`** replaces `-exec basename {} \;` — the `{/}` template returns the filename component only, with no subprocess per result.
- **`sd` multiline anchor** — `sd '(?m)^' 'PREFIX'` adds a prefix to every line. Bare `sd '^' 'PREFIX'` only matches the start of the entire input string (Rust regex default). Always use `(?m)` for per-line operations.
- **`choose` is 0-indexed** — `awk '{print $1}'` → `choose 0`; `awk '{print $3}'` → `choose 2`. Retain `awk` for formatted `printf` output (`%3d × %s`) since `choose` has no equivalent.
- **Never commit** generated files in `output/`, `analysis/`, or `logs/`.

## Regex Pattern Guidelines

- Case-insensitive: `-i` flag
- Flexible spacing: `.*` between terms (`chunk.*strateg`)
- Alternatives: `(recursive|hierarch|tree).{0,25}(chunk|split)`
- Word boundaries: `\b(384|768|1024)\b.*dim`
- Context lines: `--context 4`
- Result cap: `--max-count 75`

## `Query::safe_rga` Default Flags

Defined in `lib/queries/helpers.sh`. These apply to every search:

```
--ignore-file="${HOME}/.gitignore"
--hidden
--rga-accurate
--rga-adapters='poppler,pandoc'
-j 4
```

## Output Structure

```
output/run_YYYYMMDD_HHMMSS/<source_dir>/<category>/
    *.jsonl              — structured: {file, line, match}
    <subcategory>/
        chunk_NNNN.md    — YAML frontmatter + context lines (one file per match group)
                           Body lines formatted as "linenum: content" for both match
                           lines (rga: "file:linenum:content") and context lines
                           (rga: "file-linenum-content"). Normalised by fmt_line() in
                           lib/queries/helpers.sh.

analysis/analysis_YYYYMMDD_HHMMSS/
    inventory.md     — file counts and sizes per category
    patterns.md      — method signatures and term frequencies
    strategy.md      — compilation recommendations
    samples/         — stratified samples (50 JSONL / 100 raw lines per file)

logs/session_YYYYMMDD_HHMMSS.log
```

## Use Context7 MCP for Loading Documentation

Context7 MCP is available to fetch up-to-date documentation with code examples.

**Recommended library IDs:**

- `/beaconbay/ck` - Semantic code search tool that finds code by meaning, not just keywords. Extends grep functionality to understand conceptual searches and integrate with AI agents via MCP.
- `/websites/help_obsidian_md_cli` - Obsidian CLI for controlling Obsidian from the terminal; vault search, note creation, daily notes, and plugin management.
- `/burntsushi/ripgrep` - ripgrep (rg): fast line-oriented regex search tool; type filtering (`-t`/`-T`), glob patterns (`-g`), context lines (`-C`), JSON output, and gitignore-aware recursive search.
- `/phiresky/ripgrep-all` - ripgrep-all (rga): adapter-based multi-format search over PDFs, Office docs, archives, SQLite, and more. Covers `--rga-adapters`, `--rga-accurate`, caching, and custom adapter config.
- `/jqlang/jq` - jq command-line JSON processor; filters, `select`, `map`, `with_entries`, pipes, and transformation patterns.
- `/sharkdp/fd` - fd: fast `find` alternative; flags for type filtering (`-t`), extension (`-e`), depth (`-d`), parallel exec (`-x`/`-X`), and placeholder syntax.
- `/chmln/sd` - sd: intuitive find-and-replace CLI (modern sed alternative); readable split syntax, capture groups, in-place file editing, and 2-12x faster than sed via memory-mapped I/O.
- `/theryangeary/choose` - choose: fast `cut`/`awk` alternative for field selection; zero-indexed fields, Python-style slice ranges, negative indexing, and custom regex separators (`-f`).

## Use Codemap CLI for Codebase Navigation

Codemap CLI is available for intelligent codebase visualization and navigation.

**Required Usage** - You MUST use `codemap --diff` to research changes different from default branch, and `git diff` + `git status` to research current working state.

### Quick Start

```bash
codemap .                    # Project tree
codemap --only sh .          # Just shell files
codemap --exclude output,logs,analysis .  # Hide generated dirs
codemap --depth 2 .          # Limit depth
codemap --diff               # What changed vs main
codemap --deps .             # Dependency flow
```

### Options

| Flag | Description |
|------|-------------|
| `--depth, -d <n>` | Limit tree depth (0 = unlimited) |
| `--only <exts>` | Only show files with these extensions |
| `--exclude <patterns>` | Exclude files matching patterns |
| `--diff` | Show files changed vs main branch |
| `--ref <branch>` | Branch to compare against (with --diff) |
| `--deps` | Dependency flow mode |
| `--importers <file>` | Check who imports a file |
| `--skyline` | City skyline visualization |
| `--json` | Output JSON |

**Smart pattern matching** - no quotes needed:
- `.sh` - any `.sh` file
- `output` - any `/output/` directory
- `*Test*` - glob pattern

### Diff Mode

```bash
codemap --diff
codemap --diff --ref develop
```
