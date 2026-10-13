#!/usr/bin/env bash
# scripts/ui.sh — shared visual layer for dot/* commands.
# Sourced, never executed. UTF-8 safe (TERM=dumb degrades to ASCII).
# Nerd-Font glyphs only if they render, else ASCII fallback.
#
# Layout contract (compact):
#   step "title" ............ runs body, prints  ok (0.4s) | FAIL
#   detail "text" ........... indented detail (dim)
#   summary "50 ok, 0 fail" . final line with counts
# Sections print a header once, not per line (that was the noise).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "XX ui.sh is sourced, not executed." >&2
  exit 1
fi

# --- capability probe (once) ------------------------------------------------
__UI_FANCY=0
if [[ "${TERM:-dumb}" != "dumb" ]] && [[ "${NO_COLOR:-}" == "" ]]; then
  __UI_FANCY=1
fi
# Nerd font present? (fc-list exists + hit) — else ASCII.
__UI_NERD=0
if command -v fc-list >/dev/null 2>&1 && fc-list 2>/dev/null | grep -qi 'nerd'; then
  __UI_NERD=1
fi

if [[ $__UI_FANCY -eq 1 ]]; then
  __C_B=$'\033[1;34m' __C_G=$'\033[1;32m' __C_Y=$'\033[1;33m'
  __C_R=$'\033[1;31m' __C_D=$'\033[2m' __C_X=$'\033[0m'
else
  __C_B='' __C_G='' __C_Y='' __C_R='' __C_D='' __C_X=''
fi

if [[ $__UI_NERD -eq 1 ]]; then
  __G_OK='✓' __G_FAIL='✗' __G_WARN='!' __G_ARROW='›'
else
  __G_OK='ok' __G_FAIL='FAIL' __G_WARN='warn' __G_ARROW='>'
fi

# --- primitives -------------------------------------------------------------
# ui_step <title> <cmd...>: one line, result on the right. Body output
# only on error (compact) — details come via ui_detail BEFORE.
ui_step() {
  local title="$1"
  shift
  local t0 t1 dt out rc
  t0=$(date +%s.%N)
  out="$("$@" 2>&1)" && rc=0 || rc=$?
  t1=$(date +%s.%N)
  dt=$(awk "BEGIN{printf \"%.1fs\", $t1 - $t0}")
  if [[ $rc -eq 0 ]]; then
    printf '%s %s %s%s %s(%s)%s\n' \
      "${__C_G}${__G_OK}${__C_X}" "$title" "${__C_D}" "" "$dt" ""
  else
    printf '%s %s %s(%s)%s\n' "${__C_R}${__G_FAIL}${__C_X}" "$title" "${__C_D}" "$dt" "${__C_X}"
    printf '%s\n' "$out" | sed 's/^/    /'
  fi
  return $rc
}

ui_detail() { printf '%s  %s %s%s\n' "${__C_D}" "${__G_ARROW}" "$*" "${__C_X}"; }
# ui_link <name> <state>: one linked entry. state: new|changed|kept.
# kept is dim (less noise), new/changed stand out.
ui_link() {
  local name="$1" state="${2:-kept}"
  case "$state" in
    new) printf '  %s %-14s %snew%s\n' "${__G_ARROW}" "$name" "${__C_G}" "${__C_X}" ;;
    changed) printf '  %s %-14s %supdated%s\n' "${__G_ARROW}" "$name" "${__C_Y}" "${__C_X}" ;;
    *) printf '%s  %s %s%s\n' "${__C_D}" "${__G_ARROW}" "$name" "${__C_X}" ;;
  esac
}
# ui_box <cmd...>: captures output, indents it dim (for nh/nixos output).
ui_box() {
  local out rc
  out="$("$@" 2>&1)" && rc=0 || rc=$?
  printf '%s\n' "$out" | sed "s/^/${__C_D}  │ ${__C_X}/"
  return $rc
}
# ui_head <title>: dim section header, no icon (minimal, matches starship/nvim).
ui_head() { printf '\n%s── %s ──%s\n' "${__C_D}" "$*" "${__C_X}"; }
# ui_warn / ui_err: always emitted (even in quiet mode).
ui_warn() { printf '%s %s%s\n' "${__C_Y}${__G_WARN}${__C_X}" "$*" >&2; }
ui_err() { printf '%s %s%s\n' "${__C_R}${__G_FAIL}${__C_X}" "$*" >&2; }
# ui_summary <ok> <fail> <warn>: final line.
ui_summary() {
  local ok_n="$1" fail_n="$2" warn_n="$3"
  if [[ "$fail_n" -eq 0 ]]; then
    printf '\n%s %s ok, %s warn%s\n' "${__C_G}${__G_OK}${__C_X}" "$ok_n" "$warn_n" ""
  else
    printf '\n%s %s ok, %s FAIL, %s warn%s\n' "${__C_R}${__G_FAIL}${__C_X}" "$ok_n" "$fail_n" "$warn_n" ""
  fi
  [[ "$fail_n" -eq 0 ]]
}
