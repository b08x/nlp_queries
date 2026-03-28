#!/usr/bin/env bash
# shellcheck shell=bash
# lib/queries.sh — Loader: sources all Query:: function scripts from lib/queries/
#
# Callers source this file; individual functions live in lib/queries/*.sh.
# set -euo pipefail and IFS are set here once so sub-files inherit them without
# re-declaring — sub-files are pure function libraries with no side effects.
#
# Usage (bin scripts):
#   source "${LIB_DIR}/queries.sh"
#   Query::run_chunking ~/my-repo output/run_20240101_120000/my-repo

set -euo pipefail
IFS=$'\n\t'

_queries_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/queries"

for _queries_file in \
  "${_queries_dir}/helpers.sh" \
  "${_queries_dir}/ck.sh" \
  "${_queries_dir}/chunking.sh" \
  "${_queries_dir}/embedding.sh" \
  "${_queries_dir}/preprocessing.sh" \
  "${_queries_dir}/parsers.sh" \
  "${_queries_dir}/pipelines.sh" \
  "${_queries_dir}/models.sh" \
  "${_queries_dir}/search.sh" \
  "${_queries_dir}/configs.sh" \
  "${_queries_dir}/graphs.sh" \
  "${_queries_dir}/multimodal.sh" \
  "${_queries_dir}/databases.sh"; do
  # shellcheck source=/dev/null
  source "${_queries_file}"
done

unset _queries_dir _queries_file
