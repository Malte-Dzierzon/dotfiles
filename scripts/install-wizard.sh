#!/usr/bin/env bash
# install-wizard.sh — staged installer TUI: choices -> local.nix -> apply.
# Usage: install-wizard.sh --apply [--dry-run] [--defaults]
#   --dry-run: write local.nix, build only (no switch).
#   --defaults: non-interactive, keep current values (for tests/CI).
#
# UI: gum when available AND on a TTY (arrows/space/enter/esc natively),
# dialog second, otherwise a pure-bash fullscreen-ish TUI with the same
# staged look (works on minimal NixOS, TERM=dumb-safe ASCII fallback).
# Nothing is written before the review screen confirms (except --defaults).
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DRY_RUN=0 DEFAULTS=0
for _a in "$@"; do
  [[ "$_a" == "--dry-run" ]] && DRY_RUN=1
  [[ "$_a" == "--defaults" ]] && DEFAULTS=1
done
HAVE_GUM=0 HAVE_DIALOG=0
command -v gum >/dev/null 2>&1 && HAVE_GUM=1
command -v dialog >/dev/null 2>&1 && HAVE_DIALOG=1
HAVE_TTY=0
{ : </dev/tty; } 2>/dev/null && HAVE_TTY=1

# --- style (Nyxuri: single palette; fancy only when the terminal supports it)
T_FANCY=0
if [[ "${TERM:-dumb}" != "dumb" && -z "${NO_COLOR:-}" ]]; then T_FANCY=1; fi
if [[ $T_FANCY -eq 1 ]]; then
  C_B=$'\033[1m' C_DIM=$'\033[2m' C_ACC=$'\033[1;36m' C_OK=$'\033[1;32m'
  C_WARN=$'\033[1;33m' C_ERR=$'\033[1;31m' C_X=$'\033[0m' C_REV=$'\033[7m'
else
  C_B='' C_DIM='' C_ACC='' C_OK='' C_WARN='' C_ERR='' C_X='' C_REV=''
fi
COLS=80
if command -v tput >/dev/null 2>&1; then COLS="$(tput cols 2>/dev/null || echo 80)"; fi
[[ "$COLS" -ge 40 ]] || COLS=40
RULECH="-"
[[ "${LC_ALL:-${LANG:-}}" == *UTF-8* || "${LC_ALL:-${LANG:-}}" == *utf8* ]] && RULECH="─"
rule() { local n=$((COLS - 2)); printf '%s%*s%s\n' "$C_DIM" "$n" '' '' | tr ' ' "$RULECH"; printf '%s' "$C_X"; }
# ui <n> <total> <title>: staged header.
ui() { printf '\n%s[%s/%s]  %s%s\n' "$C_ACC" "$1" "$2" "$3" "$C_X"; rule; }
ui_note() { printf '%s%s%s\n' "$C_DIM" "$*" "$C_X" >&2; }
ui_err() { printf '%s! %s%s\n' "$C_ERR" "$*" "$C_X" >&2; }

_tty_in() { # read one line: /dev/tty preferred, stdin fallback (tests/pipes).
  if [[ $HAVE_TTY -eq 1 ]] && IFS= read -r "$1" </dev/tty 2>/dev/null; then return 0; fi
  IFS= read -r "$1" || return 1
}

TOTAL=6

# _menu <cur> <def> <opt...> -> prints choice; rc=1 = back/abort.
_menu() {
  local cur="$1" prompt="$2" def="$3"
  shift 3
  local opts=("$@") choice=""
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then
    choice="$(gum choose --header "$cur — $prompt (Esc = back)" --selected "$def" "${opts[@]}" </dev/tty 2>/dev/null)" \
      && [[ -n "$choice" ]] && { printf '%s' "$choice"; return 0; }
    return 1
  fi
  if [[ $HAVE_DIALOG -eq 1 && $HAVE_TTY -eq 1 ]]; then
    local args=() n=0
    for o in "${opts[@]}"; do
      n=$((n + 1))
      if [[ "$o" == "$def" ]]; then args+=("$n" "$o" "on"); else args+=("$n" "$o" "off"); fi
    done
    # shellcheck disable=SC2327,SC2328
    choice="$(dialog --clear --backtitle "dotfiles installer" --title "$cur" \
      --radiolist "$prompt (Cancel = back)" 16 60 "$n" "${args[@]}" 2>&1 >/dev/tty </dev/tty)" \
      && [[ -n "$choice" ]] && { printf '%s' "${opts[$((choice - 1))]}"; return 0; }
    return 1
  fi
  # bash TUI: aligned list, default marked, number/Enter/0.
  printf '  %s\n' "$prompt" >&2
  local i=0
  for o in "${opts[@]}"; do
    i=$((i + 1))
    if [[ "$o" == "$def" ]]; then printf '  %s%2d) %-44s [default]%s\n' "$C_REV" "$i" "$o" "$C_X" >&2
    else printf '  %2d) %s\n' "$i" "$o" >&2; fi
  done
  printf '  %s0) back%s  Choice [Enter=%s]: ' "$C_DIM" "$C_X" "$def" >&2
  _tty_in choice || return 1
  [[ -z "$choice" ]] && { printf '%s' "$def"; return 0; }
  [[ "$choice" == "0" ]] && return 1
  [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#opts[@]})) || return 1
  printf '%s' "${opts[$((choice - 1))]}"
}

# _ask <cur> <prompt> <default> -> prints answer; rc=1 = back/abort.
_ask() {
  local cur="$1" prompt="$2" def="$3" ans=""
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then
    ans="$(gum input --header "$cur" --prompt "$prompt " --value "$def" </dev/tty 2>/dev/null)" && {
      printf '%s' "${ans:-$def}"
      return 0
    }
    return 1
  fi
  printf '  %s [default: %s] (empty=keep, - =back): ' "$prompt" "$def" >&2
  _tty_in ans || return 1
  [[ "$ans" == "-" ]] && return 1
  printf '%s' "${ans:-$def}"
}

# _confirm <text> -> rc 0 on yes.
_confirm() {
  local text="$1" ans=""
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then gum confirm "$text" </dev/tty 2>/dev/null; return $?; fi
  if [[ $HAVE_DIALOG -eq 1 && $HAVE_TTY -eq 1 ]]; then
    dialog --clear --backtitle "dotfiles installer" --yesno "$text" 10 60 >/dev/tty 2>&1 </dev/tty; return $?
  fi
  printf '%s [y/N]: ' "$text" >&2
  _tty_in ans || return 1
  [[ "$ans" == [yYjJ]* ]]
}

# _multiselect <cur> <preselected-csv> <opt...> -> prints csv; rc=1 = back.
_multiselect() {
  local cur="$1" pre="$2"
  shift 2
  local opts=("$@") out=""
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then
    local args=()
    for o in "${opts[@]}"; do
      if [[ ",$pre," == *",$o,"* ]]; then args+=("--selected=$o"); fi
    done
    if out="$(gum choose --no-limit --header "$cur (Space = toggle, Enter = ok, Esc = back)" "${args[@]}" "${opts[@]}" </dev/tty 2>/dev/null)" && [[ -n "$out" ]]; then
      printf '%s' "$out" | tr '\n' ',' | sed 's/,$//'
      return 0
    fi
    return 1
  fi
  local i=0
  for o in "${opts[@]}"; do
    i=$((i + 1))
    if [[ ",$pre," == *",$o,"* ]]; then printf '  %s%2d) [x] %s%s\n' "$C_OK" "$i" "$o" "$C_X" >&2
    else printf '  %2d) [ ] %s\n' "$i" "$o" >&2; fi
  done
  printf '  Numbers comma-separated (Enter=keep, 0=back): ' >&2
  local raw sel=() n
  _tty_in raw || return 1
  [[ -z "$raw" ]] && { printf '%s' "$pre"; return 0; }
  [[ "$raw" == "0" ]] && return 1
  IFS=',' read -ra sel <<<"$raw"
  for n in "${sel[@]}"; do
    n="${n// /}"
    [[ "$n" =~ ^[0-9]+$ ]] && ((n >= 1 && n <= ${#opts[@]})) || return 1
    out+="${opts[$((n - 1))]},"
  done
  printf '%s' "${out%,}"
}

# --- answers (defaults = current settings.nix) ---
KBD="de" KVARIANT="" PROFILE="laptop" USERNAME="xealom" HOSTNAME="nixos"
TIMEZONE="Europe/Berlin" MAINLOCALE="en_US.UTF-8" REGIONAL="de_DE.UTF-8"
BUNDLES="core,terminal,editor,desktop,browser,dev,latex,notes,media,gaming,godot,chat,net,fun"
GITNAME="Malte Dzierzon" GITEMAIL="malte@dzierzon.example"
CUSTOM_KBD=""
ALL_BUNDLES=(core terminal editor desktop browser dev latex notes media gaming godot chat net fun)
BLURBS=(core:"CLI basis" terminal:"foot/kitty/alacritty" editor:"Zed + Neovim" desktop:"walker, nautilus, tools"
  browser:"Zen (flake pin)" dev:"gh, lazygit, agents" latex:"texlive + zathura" notes:"obsidian, readest"
  media:"mpd, kew, mpv" gaming:"prismlauncher, steam" godot:"godot engine" chat:"signal, concord" net:"nmap, bluetooth" fun:"toofan typing")

step_hw() { # 1/6: profile only — real hardware comes from hardware-configuration.nix.
  ui "1" "$TOTAL" "Hardware profile"
  ui_note "Machine quirks only. Hardware detection stays in hardware-configuration.nix."
  local c
  c="$(_menu "Profile" "Machine type:" "$PROFILE" \
    "laptop — portable quirks (e.g. intel_vbtn blacklist)" \
    "desktop — no laptop quirks")" || return 1
  PROFILE="${c%% *}"
}

step_identity() { # 2/6
  ui "2" "$TOTAL" "Identity & locale"
  USERNAME="$(_ask "User" "Username:" "$USERNAME")" || return 1
  HOSTNAME="$(_ask "Host" "Hostname:" "$HOSTNAME")" || return 1
  TIMEZONE="$(_ask "Time" "Timezone (IANA):" "$TIMEZONE")" || return 1
  MAINLOCALE="$(_ask "Locale" "System locale:" "$MAINLOCALE")" || return 1
  REGIONAL="$(_ask "Locale" "Regional LC_*:" "$REGIONAL")" || return 1
  [[ "$USERNAME" =~ ^[a-z][a-z0-9_-]*$ ]] || { ui_err "Username '$USERNAME' invalid (lowercase, [a-z0-9_-])."; return 1; }
  [[ "$HOSTNAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || { ui_err "Hostname '$HOSTNAME' invalid."; return 1; }
  local f
  for f in HOSTNAME TIMEZONE MAINLOCALE REGIONAL; do
    [[ "${!f}" != *['"'\$]* ]] || { ui_err "Invalid character in $f (no \", \\, \$)."; return 1; }
  done
  if [[ -d /usr/share/zoneinfo && ! -e "/usr/share/zoneinfo/$TIMEZONE" ]]; then
    ui_err "Timezone '$TIMEZONE' not in /usr/share/zoneinfo."; return 1
  fi
}

step_keyboard() { # 3/6
  ui "3" "$TOTAL" "Keyboard"
  ui_note "Applies to console + XKB + greeter; Umbriel follows the system layout."
  local c
  c="$(_menu "Layout" "Physical layout:" "$KBD" \
    "de — German QWERTZ" "us — US English QWERTY" "gb — UK English QWERTY" "custom — other (xkbcli name)")" || return 1
  case "$c" in
    de*) KBD="de" ;;
    us*) KBD="us" ;;
    gb*) KBD="gb" ;;
    custom*)
      CUSTOM_KBD="$(_ask "Layout" "XKB layout name (e.g. fr, neo):" "fr")" || return 1
      KBD="$CUSTOM_KBD"
      ui_note "Custom layout: console keymap = XKB name; adjust local.nix on divergence."
      ;;
  esac
  if [[ "$KBD" == "us" ]]; then
    local v
    v="$(_menu "Variant" "US variant:" "${KVARIANT:-none (plain US)}" \
      "intl — international, dead keys" "altgr-intl — AltGr only" "none — plain US")" || return 1
    case "$v" in
      intl*) KVARIANT="intl" ;;
      altgr*) KVARIANT="altgr-intl" ;;
      *) KVARIANT="" ;;
    esac
  else
    KVARIANT=""
  fi
}

step_desktop() { # 4/6: fixed compositor info, no questions.
  ui "4" "$TOTAL" "Desktop"
  printf '  Compositor  Umbriel (flake module)\n  Shell       Noctalia (+ greeter, always on)\n  Terminal    foot\n' >&2
  ui_note "No choices here — desktop is fixed. Apps come next."
}

step_bundles() { # 5/6
  ui "5" "$TOTAL" "Applications"
  ui_note "Shell+greeter always on. At least one bundle (core recommended)."
  local csv i=0 b
  if [[ $HAVE_GUM -eq 0 && $HAVE_DIALOG -eq 0 ]]; then
    ui_note "Bundle contents:"
    for b in "${ALL_BUNDLES[@]}"; do
      for e in "${BLURBS[@]}"; do [[ "$e" == "$b:"* ]] && { printf '  %-9s %s\n' "$b" "${e#*:}" >&2; break; }; done
    done
  fi
  csv="$(_multiselect "Bundles" "$BUNDLES" "${ALL_BUNDLES[@]}")" || return 1
  [[ -z "$csv" ]] && { ui_err "Empty selection — keep core at minimum."; return 1; }
  BUNDLES="$csv"
}

_console_for() {
  case "$1" in
    de) printf 'de' ;;
    us) printf 'us' ;;
    gb) printf 'uk' ;;
    *) printf '%s' "$1" ;;
  esac
}

write_local_nix() {
  local bundle_lines b
  bundle_lines=""
  IFS=',' read -ra _bs <<<"$BUNDLES"
  local last="${_bs[${#_bs[@]}-1]}"
  for b in "${_bs[@]}"; do bundle_lines+="    \"$b\""; [[ "$b" != "$last" ]] && bundle_lines+=$'\n'; done
  cat >"$REPO/hosts/nixos/local.nix" <<EOF
# Generated by scripts/install-wizard.sh on $(date -u +%F) — per machine, git-ignored.
{lib, ...}: {
  lysec = {
    username = "$USERNAME";
    hostname = "$HOSTNAME";
    keyboardLayout = "$KBD";
    keyboardVariant = "$KVARIANT";
    consoleKeyMap = "$(_console_for "$KBD")";
    profile = "$PROFILE";
    timezone = "$TIMEZONE";
    mainLocale = "$MAINLOCALE";
    regionalLocale = "$REGIONAL";
    bundles = [
$bundle_lines
    ];
    git.name = "$GITNAME";
    git.email = "$GITEMAIL";
  };
}
EOF
  printf '%sok%s local.nix: %s@%s, kbd %s/%s, profile %s\n' "$C_OK" "$C_X" "$USERNAME" "$HOSTNAME" "$KBD" "$KVARIANT" "$PROFILE" >&2
}

review_screen() { # 6/6
  ui "6" "$TOTAL" "Review"
  printf '  %-10s %s@%s\n  %-10s %s / %s\n  %-10s %s (%s XKB, %s console)\n  %-10s %s\n  %-10s %s\n  %-10s %s\n' \
    "User" "$USERNAME" "$HOSTNAME" "Time" "$TIMEZONE" "$MAINLOCALE" \
    "Keyboard" "$KBD" "${KVARIANT:-plain}" "$(_console_for "$KBD")" \
    "Profile" "$PROFILE" "Bundles" "$BUNDLES" "Effect" "write local.nix, build, then switch" >&2
  rule
}

run_apply() {
  if [[ $DEFAULTS -eq 1 ]]; then
    write_local_nix
    if [[ $DRY_RUN -eq 1 ]]; then exec "$REPO/scripts/apply.sh" --dry-run; else exec "$REPO/scripts/apply.sh"; fi
  fi
  ui_note "dotfiles installer — Esc/0 goes back. Nothing is written until Review confirms."
  step_hw || return 1
  step_identity || return 1
  step_keyboard || return 1
  step_desktop
  step_bundles || return 1
  review_screen
  _confirm "Write local.nix and install?" || { ui_note "Aborted — nothing written, nothing rebuilt."; return 2; }
  write_local_nix
  if [[ $DRY_RUN -eq 1 ]]; then exec "$REPO/scripts/apply.sh" --dry-run; else exec "$REPO/scripts/apply.sh"; fi
}

run_apply
rc=$?
if [[ $rc -ne 0 ]]; then ui_note "Wizard exited without changes (abort or input error)."; fi
exit $rc
