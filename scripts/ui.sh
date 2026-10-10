#!/usr/bin/env bash
# scripts/ui.sh — shared visual layer for dot/* commands.
# Sourced, never executed. UTF-8 safe (TERM=dumb degrades to ASCII).
# Nerd-Font glyphs only if they render, else ASCII fallback.
#
# Layout contract (kompakt):
#   step "titel" ............ runs body, prints  ok (0.4s) | FAIL
#   detail "text" ........... eingerueckte Einzelheit (dim)
#   summary "50 ok, 0 fail" . Schlusszeile mit Zaehlung
# Sections print a header once, not per line (das war das Rauschen).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "XX ui.sh nur sourcen." >&2
  exit 1
fi

# --- capability probe (once) ------------------------------------------------
__UI_FANCY=0
if [[ "${TERM:-dumb}" != "dumb" ]] && [[ "${NO_COLOR:-}" == "" ]]; then
  __UI_FANCY=1
fi
# Nerd-Font da? (fc-list vorhanden + Treffer) — sonst ASCII.
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
  __G_OK='󰄬' __G_FAIL='󰅖' __G_WARN='󰀪' __G_STEP='󰜴' __G_ARROW='❯'
else
  __G_OK='ok' __G_FAIL='FAIL' __G_WARN='warn' __G_STEP='::' __G_ARROW='>'
fi

# --- primitives -------------------------------------------------------------
# ui_step <titel> <cmd...>: eine Zeile, Ergebnis rechts. Output des Bodys
# nur bei Fehler (kompakt) — Details kommen ueber ui_detail VORHER.
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

# ui_detail <text>: dimme Einzelheit (Konfig-Name, Pfad, Version).
ui_detail() { printf '%s  %s %s%s\n' "${__C_D}" "${__G_ARROW}" "$*" "${__C_X}"; }
# ui_head <titel>: Sektionskopf, einmal pro Phase.
ui_head() { printf '\n%s%s %s%s\n' "${__C_B}" "${__G_STEP}" "$*" "${__C_X}"; }
# ui_warn / ui_err: gehen immer raus (auch im Quiet-Modus).
ui_warn() { printf '%s %s%s\n' "${__C_Y}${__G_WARN}${__C_X}" "$*" >&2; }
ui_err() { printf '%s %s%s\n' "${__C_R}${__G_FAIL}${__C_X}" "$*" >&2; }
# ui_summary <ok> <fail> <warn>: Schlusszeile.
ui_summary() {
  local ok_n="$1" fail_n="$2" warn_n="$3"
  if [[ "$fail_n" -eq 0 ]]; then
    printf '\n%s %s ok, %s warn%s\n' "${__C_G}${__G_OK}${__C_X}" "$ok_n" "$warn_n" ""
  else
    printf '\n%s %s ok, %s FAIL, %s warn%s\n' "${__C_R}${__G_FAIL}${__C_X}" "$ok_n" "$fail_n" "$warn_n" ""
  fi
  [[ "$fail_n" -eq 0 ]]
}
