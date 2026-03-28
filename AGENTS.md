# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-12 20:08:39 EST  
**Commit:** c6a9505  
**Branch:** main

## OVERVIEW

Bash-based NLP strategy extraction CLI. Searches codebases for NLP/ML patterns (chunking, embeddings, preprocessing) using ripgrep-all, outputs structured JSONL/text reports via interactive Gum UI.

## STRUCTURE

```shell
nlp_queries/
├── nlp_extractor.sh          # Interactive CLI - select categories, run extractions
├── nlp_strategy_analyzer.sh  # Automated 5-stage analysis pipeline
├── diag_extraction.sh         # Diagnostic utility for extraction runs
├── lib/
│   ├── queries.sh            # 10 extraction functions (rga + jq patterns)
│   └── gum_wrapper.sh        # UI framework, error traps, gum auto-install
├── output/                   # Generated: timestamped extraction runs
├── analysis/                 # Generated: analyzer output
└── logs/                     # Generated: session logs
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add extraction category | `lib/queries.sh` | Add `run_<category>_queries()`, register in `nlp_extractor.sh` |
| Modify UI/error handling | `lib/gum_wrapper.sh` | Trap functions, color scheme, gum wrappers |
| Run interactive extraction | `./nlp_extractor.sh` | Requires rga, jq, gum |
| Run analysis pipeline | `./nlp_strategy_analyzer.sh` | Processes extraction outputs |
| Debug extraction structure | `./diag_extraction.sh` | Validates run directories |
| Test regex patterns | Bash: `rga -i 'pattern' --type py src/` | Test before adding to queries.sh |

## CONVENTIONS

**Bash Strictness:**

- All scripts use `set -e` variants (exit on error)
- `safe_rga` wrapper: treats no-matches (exit 1) as success

**Error Handling:**

- Traps on ERR/EXIT write errors to `$ERROR_MSG` temp file
- Logs to `logs/setup_YYYYMMDD_HHMMSS.log`
- Category errors: `${SESSION_OUTPUT}/${func_name}_errors.log`

**Output Formats:**

- JSONL: `rga --json | jq -r 'select(.type == "match") | {file, line, match}'`
- Raw text: `rga --context N > output_raw.txt`

**Regex Patterns (queries.sh):**

- Case-insensitive: `-i` flag
- Flexible spacing: `.*` between terms (e.g., `chunk.*strateg`)
- Alternatives: `(recursive|hierarch|tree).{0,25}(chunk|split)`
- Word boundaries: `\b(384|768|1024)\b.*dim`
- Max results: `--max-count 75` to prevent overwhelming output

**File Type Filters:**

- Always use `--type py --type ruby --type markdown --type json` etc.
- Avoids searching binaries, images, generated files

**Safe File Iteration:**

```bash
while IFS= read -r file; do
    # process
done < <(find ... -print0 | xargs -0 ...)
```

## ANTI-PATTERNS (THIS PROJECT)

- **Never** run rga without `safe_rga` wrapper in query functions (exit 1 breaks script)
- **Never** hardcode gum path - use `$GUM` variable (supports custom locations)
- **Never** commit files in `output/`, `analysis/`, `logs/` (gitignored)
- **Never** use `echo` for user-facing messages - use gum wrappers (gum_info, gum_warn, gum_fail)
- **Never** skip file type filters in rga - causes slow searches and false positives

## UNIQUE STYLES

**Color-Coded UI (gum):**

- Purple (212): Titles, prompts, interactive elements
- Green (36): Success messages, summaries, property values
- Yellow (221): Warnings, info messages
- Red (9): Errors, failures
- White (251): Standard text

**Session Management:**

- Output dirs: `output/run_YYYYMMDD_HHMMSS/<category>/`
- Timestamped logs: `logs/setup_YYYYMMDD_HHMMSS.log`

**Gum Auto-Install:**

- First run downloads gum v0.16.0 to `~/.local/bin/`
- Checks system paths before downloading

## COMMANDS

```bash
# Interactive extraction
./nlp_extractor.sh
# Default source: $HOME/Notebook
# Prompts for custom directory

# Analysis pipeline (requires prior extraction run)
./nlp_strategy_analyzer.sh
# Processes latest run in output/

# Diagnostic check
./diag_extraction.sh
# Validates extraction run structure

# Install dependencies
sudo dnf install jq                    # Fedora
sudo apt install jq                    # Ubuntu
cargo install ripgrep-all              # rga (all platforms)

# Test extraction query
rga -i 'chunk.*strateg' --type py ~/path/to/code --json | jq .

# Manual gum install (if auto-install fails)
curl -L https://github.com/charmbracelet/gum/releases/download/v0.16.0/gum_0.16.0_Linux_x86_64.tar.gz | tar xz
mv gum ~/.local/bin/
```

## NOTES

**No Test Suite:** Project lacks pytest/jest configs. Manual testing via `./nlp_extractor.sh`.

**Missing LICENSE:** Referenced in README but file absent.

**Multiple Entry Points:** 3 scripts instead of single bin/ - each serves distinct purpose (interactive vs pipeline vs diagnostic).

**LSP Support:** No bash-ls installed. Install for linting: `npm install -g bash-language-server`.

**Dependencies:**

- ripgrep-all (rga): Multi-format search (PDFs, archives)
- jq: JSON processing
- gum: Terminal UI (auto-installed)

**rga Configuration:**

- Uses `~/.gitignore` as ignore file
- Runs with 4 parallel jobs (`-j 4`)
- Adapters: poppler (PDFs), pandoc (docs)
