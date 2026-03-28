#!/usr/bin/env bash
# shellcheck shell=bash
# lib/log.sh — Structured logging to stderr and optional log file
#
# Usage:
#   source lib/log.sh
#   Log::setup "${LOG_DIR}"   # optional; enables file logging
#   Log::info  "message"
#   Log::stage "Stage 2: Inventory"

set -euo pipefail
IFS=$'\n\t'

declare -g _LOG_FILE=""

# Log::setup <log_dir>
# Creates a timestamped log file under <log_dir>. Call once at startup.
Log::setup() {
  local log_dir="${1:-${PWD}/logs}"
  mkdir -p "${log_dir}"
  _LOG_FILE="${log_dir}/session_$(date +%Y%m%d_%H%M%S).log"
  touch "${_LOG_FILE}"
}

# Log::file — print the active log file path (empty string if none)
Log::file() {
  echo "${_LOG_FILE}"
}

# _Log::write <LEVEL> <message>
_Log::write() {
  local level="$1"
  local message="$2"
  local entry="[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}"
  echo "${entry}" >&2
  if [[ -n "${_LOG_FILE}" && -f "${_LOG_FILE}" ]]; then
    echo "${entry}" >> "${_LOG_FILE}"
  fi
}

Log::info()    { _Log::write "INFO"  "$*"; }
Log::warn()    { _Log::write "WARN"  "$*"; }
Log::error()   { _Log::write "ERROR" "$*"; }
Log::success() { _Log::write "OK"    "$*"; }

# Log::stage <title> — prominent section separator (stderr + file)
Log::stage() {
  local line="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "\n%s\n  %s\n%s\n" "${line}" "$*" "${line}" >&2
  if [[ -n "${_LOG_FILE}" && -f "${_LOG_FILE}" ]]; then
    printf "\n%s\n  %s\n%s\n" "${line}" "$*" "${line}" >> "${_LOG_FILE}"
  fi
}
