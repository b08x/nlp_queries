# NLP Strategy Extraction Tool

> An interactive CLI for discovering and cataloging NLP implementation patterns across codebases

[![Shell Script](https://img.shields.io/badge/Shell-Bash-89e051.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 🎯 Overview

**NLP Chunking Queries** is a sophisticated bash-based analysis tool that systematically searches through source code to extract and catalog patterns, configurations, and implementations related to NLP and machine learning techniques. It combines powerful search capabilities with an intuitive terminal UI to make NLP strategy discovery accessible and organized.

### What Does It Do?

This tool helps you:

- 🔍 **Discover NLP patterns** - Find chunking strategies, embedding configurations, and preprocessing logic
- 📊 **Analyze implementations** - Extract model integrations, search algorithms, and pipeline architectures
- 📝 **Document findings** - Generate structured JSONL and text reports for each extraction category
- 🎨 **Navigate results** - Beautiful terminal UI with color-coded output and interactive exploration

### Key Features

- **10 Specialized Extraction Categories** - From chunking strategies to multi-modal vision models
- **Multi-Format Search** - Searches across code (Python, Ruby, JS), configs (YAML, JSON), docs (Markdown), and even PDFs
- **Smart Pattern Matching** - Uses regex patterns tuned for common NLP/ML implementation patterns
- **Structured Output** - Results organized by category with both JSONL (machine-readable) and raw text formats
- **Session Management** - Timestamped output directories preserve each extraction run
- **Interactive UI** - Built with Gum (Charm Bracelet) for a polished developer experience

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
   git clone https://github.com/yourusername/nlp_chunking_queries.git
   cd nlp_chunking_queries
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

3. **Run the tool:**

   ```bash
   ./nlp_extractor.sh
   ```

   The tool will automatically download and install `gum` (v0.16.0) to `~/.local/bin/` if not found.

## 🚀 Usage

### Basic Workflow

1. **Launch the interactive CLI:**

   ```bash
   ./nlp_extractor.sh
   ```

2. **Configure source directory:**
   - Default: `$HOME/Notebook`
   - Enter custom path when prompted

3. **Select extraction categories:**
   - Choose one or more from 10 available strategies
   - Use arrow keys and space bar to select

4. **Review results:**
   - Output saved to timestamped directory: `output/run_YYYYMMDD_HHMMSS/`
   - Option to explore results in pager or exit

### Example Session

```bash
$ ./nlp_extractor.sh

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
nlp_chunking_queries/
├── nlp_extractor.sh          # Main CLI entry point
├── lib/
│   ├── gum_wrapper.sh        # UI framework & error handling
│   └── queries.sh            # Query functions for 10 categories
└── output/                   # Generated results (timestamped)
    └── run_YYYYMMDD_HHMMSS/
        ├── chunking/
        ├── embedding/
        ├── preprocessing/
        ├── parsers/
        ├── pipelines/
        ├── models/
        ├── search/
        ├── config/
        ├── graphs/
        └── multimodal/
```

### Core Components

#### `nlp_extractor.sh`

Main orchestrator that:

- Manages user configuration (source directory selection)
- Handles category selection via interactive menu
- Executes extraction functions with progress indicators
- Displays results and provides exploration options
- Error handling and session logging

#### `lib/gum_wrapper.sh`

UI framework providing:

- Styled terminal output (title, info, warn, fail)
- Interactive components (confirm, input, choose, filter)
- Auto-downloading of gum binary if not available
- Comprehensive error trapping and logging
- Automatic cleanup and signal handling

#### `lib/queries.sh`

Query engine containing:

- 10 specialized extraction functions
- Regex patterns for NLP/ML implementations
- `safe_rga` wrapper for graceful "no matches" handling
- JSON parsing and output formatting with `jq`
- Directory structure management

## 🔧 Technical Details

### Search Technology

**ripgrep-all (rga)** is the core search engine, chosen for:

- **Multi-format support** - Searches inside PDFs, Office docs, compressed archives
- **Speed** - Rust-based parallelized search optimized for large codebases
- **Regex power** - Full regex support with context line retrieval
- **JSON output** - Structured output for programmatic processing

### Pattern Design Philosophy

Query patterns are designed to balance:

- **Precision** - Avoid false positives (e.g., `chunk.*strateg` vs just `chunk`)
- **Recall** - Capture variations (e.g., `semantic.*split` allows "semantic_split", "semantic split", "semanticSplit")
- **Performance** - Use file type filters (`--type py`) to reduce search space

**Example pattern breakdown:**

```bash
# Matches: "recursive chunking", "hierarchical split", "tree-based chunk"
safe_rga -i '(recursive|hierarch|tree).{0,25}(chunk|split)' \
    --type markdown --type py --type ruby \
    --context 4 \
    --max-count 75 \
    "$src" > "$out/hierarchical_raw.txt"
```

- `(recursive|hierarch|tree)` - Alternative prefixes
- `.{0,25}` - Allow up to 25 characters between prefix and suffix
- `(chunk|split)` - Alternative suffixes
- `--context 4` - Include 4 lines before/after match for context
- `--max-count 75` - Limit to 75 matches to prevent overwhelming output

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

1. **Dependency checks** - Pre-flight validation of `rga` and `jq`
2. **Graceful "no matches"** - `safe_rga` wrapper treats empty results as success
3. **Session logging** - Errors logged to `${SESSION_OUTPUT}/${func_name}_errors.log`
4. **Trap functions** - Automatic cleanup on script exit or interruption

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

1. **Add query function to `lib/queries.sh`:**

   ```bash
   run_custom_queries() {
       local src="$1"
       local out="$2/custom"
       ensure_dir "$out"

       safe_rga 'your.*pattern' \
           --type py --type ruby \
           "$src" \
           --json | \
           jq -r 'select(.type == "match") | {...}' \
           > "$out/custom_results.jsonl"
   }
   ```

2. **Register in `nlp_extractor.sh`:**

   ```bash
   # Update OPTIONS array
   OPTIONS=("..." "11. Custom")

   # Add case handler
   case "$category" in
       ...
       *"11. Custom"*) execute_extraction "Custom" "run_custom_queries" || true ;;
   esac
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
# Set LOG_FILE environment variable
export LOG_FILE=/tmp/nlp_extractor.log
./nlp_extractor.sh

# View logs
tail -f /tmp/nlp_extractor.log
```

## 🤝 Contributing

Contributions are welcome! Areas for enhancement:

- **Additional extraction categories** - Security patterns, optimization techniques, etc.
- **Pattern refinement** - Improve precision/recall for existing patterns
- **Output formats** - CSV, Markdown tables, HTML reports
- **Analysis features** - Pattern frequency analysis, trend detection
- **Integration** - Export to note-taking apps, documentation generators

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [ripgrep-all](https://github.com/phiresky/ripgrep-all) - Fast multi-format search
- [Gum](https://github.com/charmbracelet/gum) - Beautiful terminal UI components
- [jq](https://stedolan.github.io/jq/) - JSON processing excellence

## 🐛 Troubleshooting

### Common Issues

**Issue:** `rga: command not found`

```bash
# Solution: Install ripgrep-all
cargo install ripgrep-all
# Or download binary from: https://github.com/phiresky/ripgrep-all/releases
```

**Issue:** `jq: command not found`

```bash
# Solution: Install jq
sudo dnf install jq  # Fedora/RHEL
sudo apt install jq  # Ubuntu/Debian
```

**Issue:** Gum auto-download fails

```bash
# Solution: Manual installation
curl -L https://github.com/charmbracelet/gum/releases/download/v0.16.0/gum_0.16.0_Linux_x86_64.tar.gz | tar xz
sudo mv gum /usr/local/bin/
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
# Ensure script is executable
chmod +x nlp_extractor.sh

# Check output directory permissions
ls -la output/
```

## 📧 Contact

For questions, issues, or suggestions:

- Open an issue on GitHub
- Email: <your.email@example.com>

---

**Happy Pattern Hunting!** 🔍✨
