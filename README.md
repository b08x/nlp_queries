# NLP Strategy Extraction Tool

> An interactive CLI for discovering and cataloging NLP implementation patterns across codebases

[![Shell Script](https://img.shields.io/badge/Shell-Bash-89e051.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 🎯 Overview

**NLP Chunking Queries** is a bash-based tool that searches source code to extract and catalog patterns, configurations, and implementations related to NLP and machine learning. It combines powerful search with an intuitive terminal UI to make NLP strategy discovery accessible.

### What Does It Do?

This tool helps you:

- 🔍 **Discover NLP patterns** — Find chunking strategies, embedding configurations, and preprocessing logic
- 📊 **Analyze implementations** — Extract model integrations, search algorithms, and pipeline architectures
- 📝 **Document findings** — Generate structured JSONL and text reports for each extraction category
- 🎨 **Navigate results** — Color-coded terminal output and interactive exploration

### Key Features

- **10 Specialized Extraction Categories** — From chunking strategies to multi-modal vision models
- **Multi-Format Search** — Searches code (Python, Ruby, JS), configs (YAML, JSON), docs (Markdown), and PDFs
- **Smart Pattern Matching** — Regex patterns tuned for common NLP/ML implementations
- **Structured Output** — Results organized by category in JSONL and raw text formats
- **Automated Analysis Pipeline** — 5-stage analysis generating strategy recommendations
- **Multi-Source Support** — Extract from multiple directories in one session
- **Session Management** — Timestamped output directories preserve each run
- **Interactive UI** — Built with Gum for a polished developer experience
- **Diagnostic Tools** — Validate extraction structure and identify issues

### Complete Workflow

```shell
┌─────────────────────────────────────────────────────────────────┐
│                        bin/nlpq.sh                               │
│                   Primary Pipeline Entrypoint                    │
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
1️⃣  EXTRACTION          2️⃣  VALIDATION       3️⃣  ANALYSIS
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ bin/nlp-extract  │─▶│ bin/nlp-diag     │─▶│ bin/nlp-analyze  │
│                  │  │                  │  │                  │
│ • Select sources │  │ • Verify runs    │  │ • Inventory      │
│ • Pick categories│  │ • Check files    │  │ • Sample data    │
│ • Run queries    │  │ • Report issues  │  │ • Extract patterns│
└──────────────────┘  └──────────────────┘  │ • Generate strategy│
        │                      │            └──────────────────┘
        ▼                      ▼                    │
output/run_TIMESTAMP/  ✓ Structure validated         ▼
├── source1/           ✓ Files present      analysis/analysis_TIMESTAMP/
│   ├── chunking/      ✓ Ready for analysis ├── inventory.md
│   ├── embedding/                          ├── patterns.md
│   └── ...                                 ├── strategy.md
└── source2/                                └── samples/
    └── ...
```

## 📦 Installation

### Prerequisites

The tool requires the following dependencies:

| Dependency | Purpose | Installation |
|------------|---------|--------------|
| **ripgrep-all (rga)** | Multi-format regex searcher | `cargo install ripgrep-all` or [download binary](https://github.com/phiresky/ripgrep-all/releases) |
| **jq** | JSON processing | `sudo dnf install jq` (Fedora) / `sudo apt install jq` (Ubuntu) |
| **gum** | Terminal UI library | Auto-downloaded on first run |

### Quick Start

1. **Clone the repository:**

   ```bash
   git clone https://github.com/b08x/nlp_queries.git
   cd nlp_queries
   ```

2. **Install dependencies:**

   ```bash
   # Fedora/RHEL
   sudo dnf install jq
   cargo install ripgrep-all

   # Ubuntu/Debian
   sudo apt install jq
   cargo install ripgrep-all
   ```

3. **Make scripts executable:**

   ```bash
   chmod +x bin/*
   ```

4. **Run the full pipeline:**

   ```bash
   # Interactive mode — prompts for mode, output dir, and source directory
   bin/nlpq.sh

   # Or specify source directory directly (runs full pipeline)
   bin/nlpq.sh ~/path/to/codebase
   ```

   The tool will automatically download and install `gum` (v0.16.0) to `~/.local/bin/` if not found.

5. **Run individual stages:**

   ```bash
   bin/nlp-extract              # Extraction only
   bin/nlp-diag                 # Validate extraction
   bin/nlp-analyze              # Run analysis pipeline
   ```

## 🚀 Usage

### Basic Workflow

**Full Pipeline (recommended):**

1. **Launch the entrypoint:**

   ```bash
   bin/nlpq.sh
   ```

2. **Select pipeline mode** — Full Pipeline, Extract Only, Analyze Only, or Diagnose Only

3. **Configure output directory** — default is `~/nlpq_TIMESTAMP`

4. **Configure source directory** (extraction modes only)
   - Default: `$HOME/Notebook`
   - Enter custom path when prompted

5. **Select extraction categories** — choose from 10 available strategies

6. **Review results** — output saved under the directory you specified

**Multi-Source Extraction:**

Pass source directories as arguments to run the full pipeline without prompts:

```bash
bin/nlpq.sh ~/Projects/ml-codebase ~/Research/nlp-experiments ~/Notebook
```

**Individual Stages:**

Run stages directly when you need more control:

```bash
bin/nlp-extract              # Extraction only (interactive)
bin/nlp-extract ~/repo1 ~/repo2  # Extraction with source dirs

bin/nlp-analyze              # Analysis on most recent extraction
bin/nlp-diag                 # Validate extraction structure
```

**Analysis Pipeline:**

After extraction, the analyzer processes the most recent run and generates:
- Inventory of discovered content
- Stratified samples for manual review
- Pattern frequency analysis
- Strategy compilation recommendations

### Example Session

```bash
$ bin/nlpq.sh

╔════════════════════════════════════════╗
║                                        ║
║      NLP Strategy Extraction           ║
║   Pattern Discovery & Agent Tagging    ║
║                                        ║
╔════════════════════════════════════════╝

⚙ Configuration
Source dir: /home/user/Projects/ml-codebase

Results: output/run_20241222_143052
Start Extraction? [Y/n]

Select Strategies:
  ◉ 1. Chunking
  ◉ 2. Embedding
  ◯ 3. Preprocessing
  ◉ 4. Parsers
  ◯ 5. Pipelines
  ◉ 6. Models
  ◯ 7. Search
  ◯ 8. Configs
  ◯ 9. Graphs
  ◯ 10. Multi-Modal

Processing...
✓ Chunking
✓ Embedding
✓ Parsers
✓ Models

Summary
Files: 12
Location: output/run_20241222_143052

Choose: Explore | Exit
```

## 💡 Use Cases

**Research & Discovery**
- Audit how different teams handle NLP tasks
- Discover implementation patterns across large codebases
- Find examples of specific techniques
- Identify inconsistencies in NLP strategy

**Documentation & Knowledge Management**
- Catalog existing NLP implementations for onboarding
- Create a reference library of proven patterns
- Extract configuration baselines for new projects
- Generate API/method inventories from legacy code

**Refactoring & Consolidation**
- Find duplicate or similar NLP implementations to consolidate
- Identify candidates for shared library extraction
- Spot outdated patterns that need modernization
- Map dependencies between NLP components

**Compliance & Standards**
- Verify adherence to NLP best practices
- Audit model usage and API integrations
- Find hardcoded values that should be configurable
- Track which embedding dimensions are in use

**Example Scenarios:**

1. **"Standardize chunking across 5 microservices"**
   - Extract chunking patterns from all services
   - Compare token windows, overlap ratios, and splitting logic
   - Generate recommendations for unified approach

2. **"What embedding models are in production?"**
   - Run embedding extraction across all repositories
   - Analyze dimension configurations and model references
   - Identify version drift and upgrade candidates

3. **"Document NLP preprocessing for the new team"**
   - Extract preprocessing and parser implementations
   - Sample representative code with context
   - Generate method catalog with signatures

## 📚 Extraction Categories

### 1. Chunking Strategies

**Extracts:**

- Semantic splitting patterns (`semantic.*split`, `chunk.*strateg`)
- Token window configurations (`token.*window`, `max.*token`)
- Hierarchical chunking logic (`recursive.*chunk`, `hierarch.*split`)

**Output:**

- `strategies.jsonl` - Matched chunking patterns with file/line references
- `token_configs.jsonl` - Token window and limit configurations
- `hierarchical_raw.txt` - Recursive/hierarchical chunking implementations

**Example pattern detected:**

```python
# File: text_splitter.py:42
chunk_strategy = "semantic_split"
max_tokens = 512
overlap = 128
```

### 2. Embedding Configurations

**Extracts:**

- Embedding model references (`sentence-transformers`, `model.*embed`)
- Vector dimensions (384, 768, 1024, 1536, 3072, 4096)
- Vector database integrations (`pgvector`, `vector.*search`)

**Output:**

- `embedding_configs.jsonl` - Model and config file references
- `dimensions_raw.txt` - Dimension specifications with context
- `vector_dbs.jsonl` - Vector database usage patterns

### 3. Preprocessing Methods

**Extracts:**

- Text cleaning and normalization logic
- Tokenizer implementations (spaCy, NLTK, tiktoken)
- Stop word removal and stemming patterns

**Output:**

- `methods_raw.txt` - Preprocessing function implementations
- `tokenizers_raw.txt` - Tokenizer configurations and usage

### 4. Parser Implementations

**Extracts:**

- Markdown splitting logic
- Section and heading parsers
- Document structure analyzers

**Output:**

- `markdown_splitters_raw.txt` - Markdown parsing implementations

### 5. Pipeline Architectures

**Extracts:**

- Pipeline class definitions
- Multi-stage processing flows
- Data transformation pipelines

**Output:**

- `architectures_raw.txt` - Pipeline design patterns

### 6. Model Integrations

**Extracts:**

- Local inference (Ollama, LM Studio)
- API-based inference (OpenAI, Anthropic, Gemini)
- Model loading and configuration

**Output:**

- `local_inference_raw.txt` - Local model usage
- `api_inference_raw.txt` - API integration patterns

### 7. Search Algorithms

**Extracts:**

- Hybrid search implementations
- Reciprocal Rank Fusion (RRF)
- Fusion algorithm patterns

**Output:**

- `hybrid_patterns_raw.txt` - Search algorithm implementations

### 8. Configuration Patterns

**Extracts:**

- Context window settings
- Token limits and constraints
- Model configuration parameters

**Output:**

- `context_windows_raw.txt` - Context and token limit configs

### 9. Knowledge Graphs

**Extracts:**

- Knowledge graph implementations
- Entity-relation extraction
- Graph database integrations

**Output:**

- `kg_raw.txt` - Knowledge graph patterns

### 10. Multi-Modal Processing

**Extracts:**

- Vision model integrations (CLIP, BLIP, LLaVA)
- Image captioning implementations
- Multi-modal fusion strategies

**Output:**

- `vision_raw.txt` - Vision and multi-modal patterns

## 🏗️ Project Structure

```
nlp_queries/
├── bin/
│   ├── nlpq.sh               # Primary entrypoint — full pipeline orchestrator
│   ├── nlp-extract           # Interactive extraction CLI
│   ├── nlp-analyze           # Automated 5-stage analysis pipeline
│   └── nlp-diag              # Diagnostic validation utility
├── lib/
│   ├── config.sh             # Shared constants (colors, sampling params)
│   ├── log.sh                # Log::* functions (info, warn, error, stage)
│   ├── gum.sh                # Gum::* UI wrappers & error handling
│   └── queries.sh            # Query::run_* functions for 10 categories
├── output/                   # Generated extraction results (timestamped)
│   └── run_YYYYMMDD_HHMMSS/
│       └── <source_dir>/
│           ├── chunking/
│           ├── embedding/
│           ├── preprocessing/
│           ├── parsers/
│           ├── pipelines/
│           ├── models/
│           ├── search/
│           ├── config/
│           ├── graphs/
│           └── multimodal/
├── analysis/                 # Generated analysis reports (timestamped)
│   └── analysis_YYYYMMDD_HHMMSS/
│       ├── inventory.md      # Content distribution summary
│       ├── patterns.md       # Extracted patterns & signatures
│       ├── strategy.md       # Compilation recommendations
│       └── samples/          # Stratified sample data
└── logs/                     # Session logs
    └── session_YYYYMMDD_HHMMSS.log
```

### Core Components

#### `bin/nlpq.sh`

Primary entrypoint that orchestrates the full pipeline:
- Interactive mode selection (Full Pipeline / Extract Only / Analyze Only / Diagnose Only)
- Prompts for output directory (default: `~/nlpq_TIMESTAMP`)
- Prompts for source directory when extraction is needed
- Exports `NLPQ_OUTPUT_BASE` and `NLPQ_ANALYSIS_OUTPUT` for downstream scripts
- Runs `nlp-extract → nlp-diag → nlp-analyze` in sequence

#### `bin/nlp-extract`

Interactive extraction orchestrator:
- Manages source directory selection (args or prompt)
- Handles category selection via interactive menu
- Supports multiple source directories via command-line arguments
- Executes `Query::run_*` functions with Gum spinners
- Displays results and provides exploration options
- Respects `NLPQ_OUTPUT_BASE` env var (defaults to `output/`)

#### `bin/nlp-analyze`

Automated 5-stage analysis pipeline:
- **Stage 1: Discovery** — Locates and selects most recent extraction run
- **Stage 2: Inventory** — Analyzes content distribution across categories
- **Stage 3: Sampling** — Performs stratified sampling (50 JSONL lines, 100 raw text lines per file)
- **Stage 4: Pattern Extraction** — Extracts method signatures, common patterns, config values
- **Stage 5: Strategy Formulation** — Generates compilation recommendations and next steps

Outputs timestamped analysis artifacts to `analysis/analysis_YYYYMMDD_HHMMSS/`

#### `bin/nlp-diag`

Diagnostic validation utility:
- Scans `output/` for extraction runs (or `NLPQ_OUTPUT_BASE` if set)
- Reports file counts by category and source directory
- Validates run structure integrity
- Identifies empty or malformed runs
- Provides recommendations for next steps

#### `lib/config.sh`

Shared constants: `GUM_VERSION`, terminal color codes, sampling parameters (`SAMPLE_SIZE_JSONL`, `SAMPLE_SIZE_RAW`, `MIN_FILE_SIZE`). Sourced first by all bin scripts.

#### `lib/log.sh`

Logging under `Log::` namespace: `Log::setup <dir>` creates a timestamped log file. `Log::info/warn/error/success/stage` write to both stderr and the log file.

#### `lib/gum.sh`

UI framework under `Gum::` namespace:
- Styled terminal output (`Gum::style`, `Gum::title`, `Gum::info`, `Gum::warn`, `Gum::fail`)
- Interactive components (`Gum::confirm`, `Gum::input`, `Gum::choose`, `Gum::spin`)
- Auto-downloads gum binary to `~/.local/bin/` if not available
- `Gum::install_traps` registers EXIT/ERR handlers

#### `lib/queries.sh`

Query engine containing:
- 10 specialized extraction functions (`Query::run_<category>`)
- Regex patterns for NLP/ML implementations
- `Query::safe_rga` wrapper for graceful "no matches" handling
- JSON parsing and output formatting with `jq`
- Directory structure management via `Query::_ensure_dir`

## 🔧 Technical Details

### Data Flow Architecture

```
User Input
    │
    ├─▶ Source Directory Selection
    │       └─▶ Single path (interactive) OR multiple paths (CLI args)
    │
    └─▶ Category Selection (multi-select)
            └─▶ 1-10 extraction categories
                    │
                    ▼
            ┌───────────────────────────────────┐
            │    Extraction Engine (queries.sh) │
            │                                    │
            │  For each category:                │
            │  ├─▶ safe_rga (ripgrep-all)       │
            │  │   • Multi-format search         │
            │  │   • Regex pattern matching      │
            │  │   • JSON output                 │
            │  │                                 │
            │  └─▶ jq (JSON processing)          │
            │      • Extract match data          │
            │      • Format JSONL records        │
            └───────────────────────────────────┘
                    │
                    ▼
            output/run_TIMESTAMP/source_dir/category/
            ├── strategies.jsonl      (structured)
            ├── token_configs.jsonl   (structured)
            └── hierarchical_raw.txt  (raw + context)
                    │
                    ▼
            ┌───────────────────────────────────┐
            │  Analysis Engine (bin/nlp-analyze) │
            │                                    │
            │  Stage 1: Discovery               │
            │  Stage 2: Inventory Analysis      │
            │  Stage 3: Stratified Sampling     │
            │  Stage 4: Pattern Extraction      │
            │  Stage 5: Strategy Formulation    │
            └───────────────────────────────────┘
                    │
                    ▼
            analysis/analysis_TIMESTAMP/
            ├── inventory.md    (summary)
            ├── patterns.md     (frequencies)
            ├── strategy.md     (recommendations)
            └── samples/        (review data)
```

### Search Technology

We chose **ripgrep-all (rga)** as the core search engine because it offers:
- **Multi-format support** — Searches inside PDFs, Office docs, compressed archives
- **Speed** — Rust-based parallelized search optimized for large codebases
- **Regex power** — Full regex support with context line retrieval
- **JSON output** — Structured output for programmatic processing

### Pattern Design Philosophy

We designed query patterns to balance:
- **Precision** — Avoid false positives (e.g., `chunk.*strateg` vs just `chunk`)
- **Recall** — Capture variations (e.g., `semantic.*split` matches "semantic_split", "semantic split", "semanticSplit")
- **Performance** — Use file type filters (`--type py`) to reduce search space

**Example pattern breakdown:**

```bash
# Matches: "recursive chunking", "hierarchical split", "tree-based chunk"
safe_rga -i '(recursive|hierarch|tree).{0,25}(chunk|split)' \
    --type markdown --type py --type ruby \
    --context 4 \
    --max-count 75 \
    "$src" > "$out/hierarchical_raw.txt"
```

| Element | Meaning |
|---------|---------|
| `(recursive|hierarch\|tree)` | Alternative prefixes |
| `.{0,25}` | Up to 25 characters between prefix and suffix |
| `(chunk\|split)` | Alternative suffixes |
| `--context 4` | 4 lines before/after match |
| `--max-count 75` | Limit matches to 75 |

### Output Formats

**JSONL (JSON Lines)** - Machine-readable format:

```json
{"file": "path/to/file.py", "line": 42, "match": "chunk_strategy = 'semantic'"}
{"file": "path/to/config.yaml", "line": 15, "match": "embedding_dim: 768"}
```

**Raw Text** - Human-readable format with context:

```
path/to/file.py:42:
    # Configure chunking strategy
    chunk_strategy = 'semantic'
    max_tokens = 512
```

### Error Handling

The tool implements robust error handling:

1. **Dependency checks** — Pre-flight validation of `rga` and `jq`
2. **Graceful "no matches"** — `safe_rga` wrapper treats empty results as success
3. **Session logging** — Errors logged to `${SESSION_OUTPUT}/${func_name}_errors.log`
4. **Trap functions** — Automatic cleanup on script exit or interruption

## 🎨 UI Components (Gum)

The tool uses [Charm Bracelet's Gum](https://github.com/charmbracelet/gum) library for:

| Component | Usage | Example |
|-----------|-------|---------|
| **gum_style** | Styled text boxes | Title headers, bordered summaries |
| **gum_input** | Text input prompts | Source directory configuration |
| **gum_choose** | Multi-select menus | Category selection |
| **gum_confirm** | Yes/no prompts | Extraction confirmation |
| **gum_spin** | Loading spinners | Extraction progress indicators |
| **gum_pager** | Scrollable output | Result exploration |

**Color-coded output:**

- 🟦 Blue (212) - Titles and headers
- 🟩 Green (36) - Success messages and summaries
- 🟨 Yellow (220) - Warnings and info
- 🟥 Red (196) - Errors and failures

## 🛠️ Development

### Adding New Extraction Categories

To add a new extraction category:

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

### Pattern Testing

Test patterns before integrating:

```bash
# Test regex pattern
rga -i 'your.*pattern' --type py /path/to/test/dir

# Test with JSON output
rga -i 'your.*pattern' --type py /path/to/test/dir --json | jq .

# Test jq transformation
rga ... --json | jq -r 'select(.type == "match") | {file: .data.path.text}'
```

### Debugging

Enable verbose logging:

```bash
# Logs are automatically created in logs/ directory
bin/nlpq.sh

# View latest log
tail -f logs/session_*.log
```

### Advanced Usage

**Complete Command Reference:**

```bash
# Full interactive pipeline (recommended)
bin/nlpq.sh

# Full pipeline with source directories (skips source dir prompt)
bin/nlpq.sh /path/to/source1 /path/to/source2

# Individual stages
bin/nlp-extract                    # Extraction only (interactive)
bin/nlp-extract ~/repo1 ~/repo2    # Extraction with source dirs
bin/nlp-analyze                    # Analysis on most recent extraction
bin/nlp-diag                       # Diagnostic validation

# Custom output directory (overrides prompt)
NLPQ_OUTPUT_BASE=~/my_results bin/nlpq.sh

# Custom gum binary location
GUM=/usr/local/bin/gum bin/nlpq.sh
```

**Working with Extraction Outputs:**

```bash
# Find latest extraction run
ls -t output/ | head -1

# Count total matches across all categories
find output/run_*/*/chunking -name "*.jsonl" -exec wc -l {} + | tail -1

# Search specific patterns in raw text
rg "semantic.*split" output/run_*/*/chunking/*_raw.txt

# Extract unique embedding dimensions
jq -r '.match' output/run_*/*/embedding/dimensions_raw.txt | \
    grep -oP '\b(384|768|1024|1536)\b' | sort -u
```

**Customizing Search Behavior:**

The `safe_rga` function in `lib/queries.sh` accepts standard rga options:

```bash
# Default configuration
--ignore-file='/var/home/b08x/.gitignore'  # Respect gitignore
--hidden                                    # Search hidden files
--rga-accurate                              # Precise mode
--rga-adapters='poppler,pandoc'            # PDF and doc support
-j 4                                        # 4 parallel jobs
```

Edit `Query::safe_rga` in `lib/queries.sh` to customize these defaults.

## 📊 Analysis Pipeline Details

The `bin/nlp-analyze` script provides deep insights into extraction results:

### Stage 1: Discovery

Scans `output/` and selects the most recent run. Displays:
- Run timestamp
- Number of source directories processed
- Category counts per source

### Stage 2: Inventory Analysis

Generates `inventory.md` with:
- File counts by category (JSONL vs raw text)
- Directory sizes
- Overall extraction statistics
- Warnings for empty categories

### Stage 3: Stratified Sampling

Creates `samples/` with representative data:
- 50 random lines per JSONL file
- 100 random lines per raw text file
- Filters files smaller than 100 bytes
- Organized by category for manual review

### Stage 4: Pattern Extraction

Generates `patterns.md`:
- **Method Signatures** — Function/class definitions from code samples
- **Common Patterns** — Frequency analysis of technical terms
- **Configuration Patterns** — Extracted dimension values and parameter settings

### Stage 5: Strategy Formulation

Produces `strategy.md`:
- Recommended compilation approaches
- Next steps for deep analysis
- Quality metrics and coverage assessment

## 🤝 Contributing

Contributions are welcome! Areas for enhancement:
- **Additional extraction categories** — Security patterns, optimization techniques
- **Pattern refinement** — Improve precision/recall for existing patterns
- **Output formats** — CSV, Markdown tables, HTML reports
- **Analysis enhancements** — Dependency graphs, cross-category correlation
- **Integration** — Export to note-taking apps, documentation generators
- **Performance** — Parallel extraction across categories

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [ripgrep-all](https://github.com/phiresky/ripgrep-all) - Fast multi-format search
- [Gum](https://github.com/charmbracelet/gum) - Beautiful terminal UI components
- [jq](https://stedolan.github.io/jq/) - JSON processing excellence

## ⚡ Performance & Limitations

### Performance Characteristics

**Extraction Speed:**
- Small codebase (<1000 files): 10-30 seconds per category
- Medium codebase (1000-10000 files): 1-5 minutes per category
- Large codebase (>10000 files): 5-15 minutes per category

**Factors affecting speed:**
- File types searched (PDF parsing is slower)
- Regex complexity (lookaheads/lookbehinds are slower)
- Directory depth and file count
- Available CPU cores (rga uses parallelization)

**Optimization tips:**

```bash
# Limit search to specific file types
# Edit lib/queries.sh to remove unnecessary --type flags

# Reduce context lines (faster, less context)
--context 2  # instead of --context 4

# Limit match count per file
--max-count 50  # instead of --max-count 75
```

### Current Limitations

**Search Scope:**
- Designed for code, configs, and documentation (not binary analysis)
- Regex patterns may miss unconventional implementations
- Limited to static code analysis (no runtime behavior tracking)

**Pattern Coverage:**
- Patterns optimized for Python, Ruby, JavaScript/TypeScript
- May miss patterns in other languages (Java, C++, Go)
- Requires manual pattern refinement for domain-specific terminology

**Output Format:**
- JSONL/text output only (no database integration)
- Manual review required for complex analysis
- No deduplication across similar matches

**Analysis Pipeline:**
- Processes most recent extraction only (no cross-run comparison)
- Sampling is random (may miss rare but important patterns)
- Strategy recommendations are generic (not project-specific)

### Roadmap

Planned enhancements:
- [ ] Database export (SQLite/PostgreSQL)
- [ ] Cross-run diff and trend analysis
- [ ] Language-specific pattern templates
- [ ] Real-time progress indicators with ETA
- [ ] Parallel category extraction
- [ ] Web UI for result exploration

## ❓ Frequently Asked Questions

**Q: Can I search multiple codebases in one run?**  
A: Yes! Pass multiple directories as arguments:
```bash
bin/nlpq.sh ~/repo1 ~/repo2 ~/repo3
```

**Q: How do I exclude certain directories?**  
A: Edit your `~/.gitignore` (rga respects gitignore by default), or modify `--ignore-file` in `lib/queries.sh`.

**Q: Can I customize the regex patterns?**  
A: Yes! Edit `lib/queries.sh` and modify patterns in each `run_<category>_queries()` function. Test with `rga` first.

**Q: Is this safe to run on production code?**  
A: Yes, it's read-only. The tool only searches files and writes to `output/`, `analysis/`, and `logs/` directories.

## 🐛 Troubleshooting

### Common Issues

**Issue:** `rga: command not found`

```bash
# Solution: Install ripgrep-all
cargo install ripgrep-all
```

**Issue:** `jq: command not found`

```bash
sudo dnf install jq  # Fedora/RHEL
sudo apt install jq  # Ubuntu/Debian
```

**Issue:** Empty results for all categories

```bash
# Check source directory contains target files
ls -R $SOURCE_DIR | grep -E '\.(py|rb|md|json|yaml)$'

# Test rga is working
rga --version
rga 'test' $SOURCE_DIR --type py
```

**Issue:** Permission denied errors

```bash
# Ensure scripts are executable
chmod +x bin/*

# Check output directory permissions
ls -la output/
```

**Issue:** Analysis pipeline fails with "No extraction runs found"

```bash
ls -la output/                    # Verify runs exist
bin/nlp-diag                      # Validate structure
bin/nlp-extract                   # Run extraction first
```

**Issue:** Stratified sampling produces empty files

```bash
# Check if extraction files have content
find output/ -name "*.jsonl" -o -name "*_raw.txt" | xargs wc -l

# Verify source directory had searchable content
# Analysis requires minimum 100 bytes per file
```

## 📧 Support & Community

### Getting Help

**Found a bug?** Open an issue with:
- OS and shell version (`bash --version`)
- Steps to reproduce
- Relevant logs from `logs/session_*.log`
- Output of `bin/nlp-diag`

**Want to contribute?** Fork the repo, create a feature branch, and submit a PR.

### Resources

- **Repository**: <https://github.com/b08x/nlp_queries>
- **Issue Tracker**: <https://github.com/b08x/nlp_queries/issues>
- **Documentation**: This README + `AGENTS.md` files

### Related Projects

- [ripgrep-all](https://github.com/phiresky/ripgrep-all) - Multi-format search engine
- [Gum](https://github.com/charmbracelet/gum) - Terminal UI toolkit
- [jq](https://stedolan.github.io/jq/) - JSON processor

---

<div align="center">

**Happy Pattern Hunting!** 🔍✨

Made with 💜 by developers, for developers

[⬆ Back to Top](#nlp-strategy-extraction-tool)

</div>
