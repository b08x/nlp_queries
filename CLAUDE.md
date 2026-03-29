# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bash-based CLI for discovering and cataloging NLP/ML implementation patterns across codebases. Uses ripgrep-all (rga) to search source code, configs, and documents; outputs structured JSONL and raw-text reports via an interactive Gum terminal UI.

## Architecture

### Entry Points (`bin/`)

- **`bin/nlp-extract`** — Interactive extraction. Prompts for source directories and strategy categories, runs `Query::run_*` functions under `Gum::spin`, writes timestamped results to `output/run_TIMESTAMP/`.
- **`bin/nlp-analyze`** — Non-interactive 5-stage pipeline: discovery → inventory → sampling → pattern extraction → strategy formulation. Operates on the most recent `output/run_*` directory.
- **`bin/nlp-diag`** — Read-only diagnostic. Scans `output/` runs and reports file counts per category.

### Shared Libraries (`lib/`)

Each library is sourced by bin scripts; none have side effects on source.

- **`lib/config.sh`** — Declares shared constants: `GUM_VERSION`, color codes (`COLOR_PURPLE=212` etc.), sampling parameters (`SAMPLE_SIZE_JSONL`, `MIN_FILE_SIZE`). Source this first.
- **`lib/log.sh`** — `Log::setup <dir>` creates a timestamped log file. `Log::info/warn/error/success/stage` write to both stderr and the log file. `Log::file` returns the active path.
- **`lib/gum.sh`** — All Gum wrappers under `Gum::` namespace. `Gum::init` locates or downloads the binary. `Gum::install_traps` registers EXIT/ERR handlers (call once per bin script). Internal runner is `Gum::_run`.
- **`lib/queries.sh`** — Ten `Query::run_*` functions (one per extraction category). `Query::safe_rga` wraps `rga` and treats exit code 1 (no matches) as success.

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
# Interactive extraction (prompts for source dir and categories)
bin/nlp-extract

# Multi-source batch extraction
bin/nlp-extract ~/repo1 ~/repo2 ~/repo3

# Analysis pipeline (processes most recent output/run_*)
bin/nlp-analyze

# Diagnostic validation
bin/nlp-diag

# Override gum binary location
GUM=/usr/bin/gum bin/nlp-extract
```

### Dependencies

```bash
cargo install ripgrep-all   # rga
sudo dnf install jq         # Fedora/RHEL
sudo apt install jq         # Ubuntu/Debian
# gum is auto-downloaded to ~/.local/bin/gum on first run
```

### Development / Testing

```bash
# Test a regex pattern before adding to queries.sh
rga -i 'chunk.*strateg' --type py ~/test/source --json | jq .

# Test a Query:: function directly
source lib/config.sh && source lib/queries.sh
Query::run_chunking ~/source /tmp/test_out

# View session log
tail -f logs/session_*.log

# Count result files across a run
find output/run_* -name "*.jsonl" -o -name "*_raw.txt" | wc -l
```

## Adding New Extraction Categories

1. **Add `Query::run_<name>` to `lib/queries.sh`:**

```bash
Query::run_custom() {
  local src="$1"
  local out="$2/custom"
  Query::_ensure_dir "${out}"

  Query::safe_rga -i 'your.*pattern' \
    --type py --type ruby \
    "${src}" --json | \
    jq -r 'select(.type == "match") |
           {file: .data.path.text, match: .data.lines.text}' \
    > "${out}/custom_results.jsonl"
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
- **Never commit** generated files in `output/`, `analysis/`, or `logs/`.

## Regex Pattern Guidelines

- Case-insensitive: `-i` flag
- Flexible spacing: `.*` between terms (`chunk.*strateg`)
- Alternatives: `(recursive|hierarch|tree).{0,25}(chunk|split)`
- Word boundaries: `\b(384|768|1024)\b.*dim`
- Context lines: `--context 4`
- Result cap: `--max-count 75`

## `Query::safe_rga` Default Flags

Defined at `lib/queries.sh`. These apply to every search:

```
--ignore-file="${HOME}/.gitignore"
--hidden
--rga-accurate
--rga-adapters='poppler,pandoc'
-j 4
```

Edit `Query::safe_rga` in `lib/queries.sh` to change global search defaults.

## Output Structure

```
output/run_YYYYMMDD_HHMMSS/<source_dir>/<category>/
    *.jsonl          — structured: {file, line, match}
    *_raw.txt        — human-readable with context lines

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

See what you're working on:

```bash
codemap --diff
codemap --diff --ref develop
```
