#!/usr/bin/env bash
# shellcheck shell=bash
# lib/gum.sh — Namespaced terminal UI wrappers using Charm's gum
#
# Usage:
#   source lib/config.sh
#   source lib/gum.sh
#   Gum::init              # locate or download gum binary
#   Gum::install_traps     # register EXIT/ERR handlers (call in bin/ scripts)
#   Gum::confirm "Ready?"

set -euo pipefail
IFS=$'\n\t'

# Resolved by Gum::init; may be overridden: GUM=/usr/bin/gum ./script
: "${GUM:=${HOME}/.local/bin/gum}"
: "${GUM_VERSION:=0.16.0}"
: "${COLOR_WHITE:=251}"
: "${COLOR_GREEN:=36}"
: "${COLOR_PURPLE:=212}"
: "${COLOR_YELLOW:=221}"
: "${COLOR_RED:=9}"

# ── Core runner ───────────────────────────────────────────────────────────────

Gum::_run() {
  if [[ ! -x "${GUM}" ]]; then
    echo "Error: gum not found or not executable at '${GUM}'" >&2
    return 1
  fi
  "${GUM}" "$@"
}

# ── Binary resolution & installation ─────────────────────────────────────────

Gum::init() {
  [[ -x "${GUM}" ]] && return 0

  local system_gum
  system_gum="$(command -v gum 2>/dev/null || true)"
  if [[ -n "${system_gum}" && -x "${system_gum}" ]]; then
    GUM="${system_gum}"
    return 0
  fi

  for candidate in /usr/bin/gum /usr/local/bin/gum "${HOME}/.local/bin/gum"; do
    if [[ -x "${candidate}" ]]; then
      GUM="${candidate}"
      return 0
    fi
  done

  _Gum::download
}

_Gum::download() {
  local tmp_dir
  tmp_dir="$(mktemp -d /tmp/.gum_install_XXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp_dir}'" RETURN

  local os_name arch_name
  os_name="$(uname -s)"
  arch_name="$(uname -m)"

  local url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_${os_name}_${arch_name}.tar.gz"

  if ! curl -Lsf "${url}" > "${tmp_dir}/gum.tar.gz"; then
    echo "Error: failed to download gum from ${url}" >&2
    return 1
  fi

  if ! tar -xf "${tmp_dir}/gum.tar.gz" --directory "${tmp_dir}"; then
    echo "Error: failed to extract gum archive" >&2
    return 1
  fi

  local gum_bin
  gum_bin="$(fd -t x -g 'gum' "${tmp_dir}" | head -1)"
  if [[ -z "${gum_bin}" ]]; then
    echo "Error: gum binary not found in downloaded archive" >&2
    return 1
  fi

  mkdir -p "${HOME}/.local/bin"
  mv "${gum_bin}" "${HOME}/.local/bin/gum"
  chmod +x "${HOME}/.local/bin/gum"
  GUM="${HOME}/.local/bin/gum"
}

# ── Color helpers ─────────────────────────────────────────────────────────────

Gum::white()  { Gum::style --foreground "${COLOR_WHITE}"  "$@"; }
Gum::purple() { Gum::style --foreground "${COLOR_PURPLE}" "$@"; }
Gum::yellow() { Gum::style --foreground "${COLOR_YELLOW}" "$@"; }
Gum::red()    { Gum::style --foreground "${COLOR_RED}"    "$@"; }
Gum::green()  { Gum::style --foreground "${COLOR_GREEN}"  "$@"; }

# ── Print helpers ─────────────────────────────────────────────────────────────

Gum::title() {
  Gum::_run join \
    "$(Gum::purple --bold "+ ")" \
    "$(Gum::purple --bold "$*")"
}

Gum::info() {
  Gum::_run join \
    "$(Gum::green --bold "• ")" \
    "$(Gum::white "$*")"
}

Gum::warn() {
  Gum::_run join \
    "$(Gum::yellow --bold "• ")" \
    "$(Gum::white "$*")"
}

Gum::fail() {
  Gum::_run join \
    "$(Gum::red --bold "• ")" \
    "$(Gum::white "$*")"
}

# ── Interactive components ────────────────────────────────────────────────────

Gum::style()   { Gum::_run style   "$@"; }
Gum::confirm() { Gum::_run confirm --prompt.foreground "${COLOR_PURPLE}" "$@"; }
Gum::input()   { Gum::_run input   --placeholder "..." --prompt "> " \
                                   --prompt.foreground "${COLOR_PURPLE}" \
                                   --header.foreground "${COLOR_PURPLE}" "$@"; }
Gum::write()   { Gum::_run write   --prompt "> " \
                                   --header.foreground "${COLOR_PURPLE}" \
                                   --show-cursor-line --char-limit 0 "$@"; }
Gum::choose()  { Gum::_run choose  --cursor "> " \
                                   --header.foreground "${COLOR_PURPLE}" \
                                   --cursor.foreground "${COLOR_PURPLE}" "$@"; }
Gum::filter()  { Gum::_run filter  --prompt "> " --indicator ">" \
                                   --placeholder "Type to filter..." --height 8 \
                                   --header.foreground "${COLOR_PURPLE}" "$@"; }
Gum::spin()    { Gum::_run spin    --spinner line \
                                   --title.foreground "${COLOR_PURPLE}" \
                                   --spinner.foreground "${COLOR_PURPLE}" "$@"; }
Gum::file()    { Gum::_run file    "$@"; }
Gum::pager()   { Gum::_run pager   "$@"; }

# ── Key/value display helpers ─────────────────────────────────────────────────

_Gum::pad() {
  local total="$1"
  local text="$2"
  local length="${#text}"
  if [[ "${length}" -ge "${total}" ]]; then
    echo "${text}"
    return 0
  fi
  printf '%s%*s\n' "${text}" $(( total - length )) ""
}

Gum::proc() {
  Gum::_run join \
    "$(Gum::green --bold "• ")" \
    "$(Gum::white --bold "$(_Gum::pad 24 "${1}")")" \
    "$(Gum::white "  >  ")" \
    "$(Gum::green "${2}")"
}

Gum::property() {
  Gum::_run join \
    "$(Gum::green --bold "• ")" \
    "$(Gum::white "$(_Gum::pad 24 "${1}")")" \
    "$(Gum::green --bold "  >  ")" \
    "$(Gum::white --bold "${2}")"
}

# ── Trap handlers ─────────────────────────────────────────────────────────────
# Call Gum::install_traps once in each bin/ entry point.

declare -g _GUM_ERR_FILE=""

Gum::install_traps() {
  _GUM_ERR_FILE="$(mktemp /tmp/.gum_err_XXXXX)"
  trap '_Gum::on_exit'  EXIT
  trap '_Gum::on_error' ERR
}

_Gum::on_error() {
  local msg="Command '${BASH_COMMAND}' failed (exit $?) in ${FUNCNAME[1]:-<top>} line ${BASH_LINENO[0]}"
  echo "${msg}" > "${_GUM_ERR_FILE}"
}

_Gum::on_exit() {
  local rc="$?"
  local error=""

  if [[ -f "${_GUM_ERR_FILE}" ]]; then
    error="$(<"${_GUM_ERR_FILE}")"
    rm -f "${_GUM_ERR_FILE}"
  fi

  if [[ "${rc}" -eq 130 ]]; then
    Gum::warn "Interrupted."
    exit 1
  fi

  if [[ "${rc}" -gt 0 ]]; then
    if [[ -n "${error}" ]]; then
      Gum::fail "${error}"
    else
      Gum::fail "An error occurred (exit ${rc})"
    fi

    local log_file
    log_file="$(Log::file 2>/dev/null || true)"
    if [[ -n "${log_file}" && -f "${log_file}" ]]; then
      Gum::warn "See ${log_file} for details."
      Gum::confirm "Show log?" && Gum::pager --show-line-numbers < "${log_file}"
    fi
  fi

  exit "${rc}"
}
