#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries/parsers.sh — Query::run_parsers
#
# Searches for document parsing and section-splitting patterns across formats:
# markdown, pdf, docx, html, xml, json, jsonl, txt, yml.
# Depends on: helpers.sh  ck.sh

Query::run_parsers() {
  local src="$1"
  local out="$2/parsers"
  Query::_ensure_dir "${out}"

  # ── Markdown ──────────────────────────────────────────────────────────
  Query::_write_raw_chunks \
    "${out}/raw/markdown_splitters" \
    'markdown.*(split|chunk|section|header)' \
    "${src}" "ruby, py, js, markdown" 10 75 \
    -n -i 'markdown.*(split|chunk|section|header)' \
    --type ruby --type py --type js --type markdown \
    --context 10 --max-count 75 \
    "${src}"

  # ── PDF (pdf-reader gem: PDF::Reader, reader.pages, page.text) ────────
  Query::_write_raw_chunks \
    "${out}/raw/pdf_parsers" \
    '(PDF::Reader|docling|reader\.pages|page\.text|pdf_reader|HexaPDF)' \
    "${src}" "ruby" 10 75 \
    -n -i '(PDF::Reader|docling|reader\.pages|page\.text|pdf_reader|HexaPDF)' \
    --type ruby --type markdown \
    --context 10 --max-count 75 \
    "${src}"

  # ── DOCX (docx gem: Docx::Document.open, paragraphs, tables) ─────────
  Query::_write_raw_chunks \
    "${out}/raw/docx_parsers" \
    '(Docx::Document|\.docx|\.paragraphs|\.tables|doc\.each_paragraph|document\.open)' \
    "${src}" "ruby" 10 75 \
    -n -i '(Docx::Document|\.docx|\.paragraphs|\.tables|doc\.each_paragraph|document\.open)' \
    --type ruby --type markdown \
    --context 10 --max-count 75 \
    "${src}"

  # ── HTML (nokogiri: Nokogiri::HTML, doc.css, doc.at_css, doc.search) ──
  Query::_write_raw_chunks \
    "${out}/raw/html_parsers" \
    '(Nokogiri::HTML|nokogiri.*parse|doc\.css|doc\.at_css|doc\.search|\.at_css|\.css\()' \
    "${src}" "ruby" 10 75 \
    -n -i '(Nokogiri::HTML|nokogiri.*parse|doc\.css|doc\.at_css|doc\.search|\.at_css|\.css\()' \
    --type ruby --type markdown \
    --context 10 --max-count 75 \
    "${src}"

  # ── XML (nokogiri: Nokogiri::XML, doc.xpath, doc.at_xpath) ───────────
  Query::_write_raw_chunks \
    "${out}/raw/xml_parsers" \
    '(Nokogiri::XML|doc\.xpath|doc\.at_xpath|\.xpath\(|\.at_xpath|Nokogiri::XML\.parse)' \
    "${src}" "ruby" 10 75 \
    -n -i '(Nokogiri::XML|doc\.xpath|doc\.at_xpath|\.xpath\(|\.at_xpath|Nokogiri::XML\.parse)' \
    --type ruby --type markdown \
    --context 10 --max-count 75 \
    "${src}"

  # ── JSON (stdlib json + yajl-ruby: JSON.parse, Yajl::Parser) ─────────
  Query::_write_raw_chunks \
    "${out}/raw/json_parsers" \
    '(JSON\.parse|JSON\.load|JSON\.pretty_generate|JSON\.generate|Yajl::Parser|yajl.*parse)' \
    "${src}" "ruby" 8 75 \
    -n -i '(JSON\.parse|JSON\.load|JSON\.pretty_generate|JSON\.generate|Yajl::Parser|yajl.*parse)' \
    --type ruby --type markdown \
    --context 8 --max-count 75 \
    "${src}"

  # ── JSONL (line-by-line JSON: File.foreach + JSON.parse, JSONL.parse) ─
  Query::_write_raw_chunks \
    "${out}/raw/jsonl_parsers" \
    '(JSONL\.parse|each_line.*JSON\.parse|foreach.*JSON\.parse|\.readlines.*map.*parse|json_stream)' \
    "${src}" "ruby" 8 75 \
    -n -i '(JSONL\.parse|each_line.*JSON\.parse|foreach.*JSON\.parse|\.readlines.*map.*parse|json_stream)' \
    --type ruby --type markdown \
    --context 8 --max-count 75 \
    "${src}"

  # ── Plain Text (IO/File stdlib: File.read, File.readlines, each_line) ─
  Query::_write_raw_chunks \
    "${out}/raw/text_parsers" \
    '(File\.read|File\.readlines|IO\.foreach|IO\.read|\.each_line|\.readlines|File\.open.*each)' \
    "${src}" "ruby" 8 75 \
    -n -i '(File\.read|File\.readlines|IO\.foreach|IO\.read|\.each_line|\.readlines|File\.open.*each)' \
    --type ruby --type markdown \
    --context 8 --max-count 75 \
    "${src}"

  # ── YAML (psych stdlib: YAML.load_file, YAML.safe_load, Psych.load) ──
  Query::_write_raw_chunks \
    "${out}/raw/yaml_parsers" \
    '(YAML\.load_file|YAML\.safe_load|YAML\.load|YAML\.dump|Psych\.load|Psych\.safe_load|\.to_yaml)' \
    "${src}" "ruby, yaml" 8 75 \
    -n -i '(YAML\.load_file|YAML\.safe_load|YAML\.load|YAML\.dump|Psych\.load|Psych\.safe_load|\.to_yaml)' \
    --type ruby --type yaml --type markdown \
    --context 8 --max-count 75 \
    "${src}"

  # ── Semantic search (all document formats) ────────────────────────────
  local _ck_root
  while IFS= read -r _ck_root; do
    Query::_run_ck_semantic \
      "ruby document parsing nokogiri docling pdf-reader docx json yaml psych file io readlines css xpath" \
      "${_ck_root}" >> "${out}/document_parsers_semantic.jsonl"
  done < <(Query::ck_find_roots "${src}")
}
