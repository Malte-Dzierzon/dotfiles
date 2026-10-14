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
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
# shellcheck source=pick.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pick.sh"

DRY_RUN=0 DEFAULTS=0
for _a in "$@"; do
  case "$_a" in
    --dry-run) DRY_RUN=1 ;;
    --defaults) DEFAULTS=1 ;;
    --apply) : ;; # accepted by apply.sh --wizard handoff, ignored here
    *) echo "XX unknown flag: $_a (use: --dry-run [--defaults])" >&2; exit 2 ;;
  esac
done
# interactive pickers need a real TTY; without one only --defaults can proceed.
HAVE_TTY=0
{ : </dev/tty; } 2>/dev/null && HAVE_TTY=1
if [[ $HAVE_TTY -eq 0 && $DEFAULTS -eq 0 ]]; then
  echo "XX no TTY for interactive installer — use --defaults (tests/CI) or run on a terminal." >&2
  exit 2
fi

# --- detect live system values (installer configures dotfiles, not the OS) ---
# Username/host/timezone/locales already exist on the installed system:
# preserve them, never prompt. Only keyboard + profile + apps are choices.
DET_USER="$(whoami 2>/dev/null || echo xealom)"
DET_HOST="$(cat /etc/hostname 2>/dev/null | tr -d ' \n' || hostname 2>/dev/null || echo nixos)"
DET_TZ="$(readlink /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##' || echo Europe/Berlin)"
DET_MAIN="$(localectl status 2>/dev/null | grep -oP 'LANG=\K\S+' || echo en_US.UTF-8)"
DET_REGION="$DET_MAIN"
DET_KBD="$(localectl status 2>/dev/null | grep -oP 'X11 Layout:\s*\K\S+' || echo de)"
DET_GITNAME="Malte Dzierzon" DET_GITEMAIL="malte@dzierzon.example"
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
if command -v tput >/dev/null 2>&1 && [[ -t 2 ]]; then COLS="$(tput cols 2>/dev/null || echo 80)"; fi
[[ "$COLS" =~ ^[0-9]+$ ]] && [[ "$COLS" -ge 40 ]] || COLS=40
# Portable rule: bash substitution (tr truncates multibyte U+2500 to 0xE2,
# which printed the replacement-char wall). UTF-8 only if the locale proves it.
RULECH="-"
if [[ "${TERM:-dumb}" != "dumb" ]] && [[ "$(locale charmap 2>/dev/null)" == "UTF-8" ]]; then RULECH="─"; fi
rule() { local n=$((COLS - 2)) line; printf -v line '%*s' "$n" ''; printf '%s%s%s\n' "$C_DIM" "${line// /$RULECH}" "$C_X"; }
# ui <n> <total> <title>: staged header.
ui() { printf '\n%s[%s/%s]  %s%s\n' "$C_ACC" "$1" "$2" "$3" "$C_X"; rule; }
ui_note() { printf '%s%s%s\n' "$C_DIM" "$*" "$C_X" >&2; }
ui_err() { printf '%s! %s%s\n' "$C_ERR" "$*" "$C_X" >&2; }

_tty_in() { # read one line: /dev/tty preferred, stdin fallback (tests/pipes).
  if [[ $HAVE_TTY -eq 1 ]] && IFS= read -r "$1" </dev/tty 2>/dev/null; then return 0; fi
  IFS= read -r "$1" || return 1
}

TOTAL=4
FOOT_SINGLE="Up/Down move · Enter select · Esc back"
FOOT_MULTI="Up/Down move · Space toggle · Enter ok · Esc back"
FOOT_FILTER="Type to filter · Up/Down move · Enter continue · Esc back"

# _rail <active-idx>: compact step rail, called before each pick.
_rail() {
  local names=(Keyboard Software Hardware Review) out="" n=0
  for n in 0 1 2 3; do
    if ((n < $1)); then out+="  [ok] ${names[$n]}   "
    elif ((n == $1)); then out+="  > ${names[$n]}   "
    else out+="  ${names[$n]}   "
    fi
  done
  _PR_STEPS="$out"
  _PR_INFO="${USERNAME:-}@${HOSTNAME:-}"
  export _PR_STEPS _PR_INFO
}

# Thin wrappers over pick.sh (identical contract: print result, rc=1 = back).
# _menu <cur> <prompt> <def> <opt...>
_menu() {
  local cur="$1" prompt="$2" def="$3"
  shift 3
  pick_single "$cur — $prompt" "$FOOT_SINGLE" "$def" "$@"
}
# _ask <cur> <prompt> <default>: type-in (no guessing identity values).
_ask() {
  local cur="$1" prompt="$2" def="$3" ans=""
  printf '  %s [%s]: ' "$prompt" "$def" >&2
  _tty_in ans || return 1
  [[ "$ans" == "-" ]] && return 1
  printf '%s' "${ans:-$def}"
}
# _confirm <text>: y/N via arrows (no silent default).
_confirm() {
  local text="$1" c=""
  c="$(pick_single "$text" "$FOOT_SINGLE" "no" "yes" "no")" || return 1
  [[ "$c" == "yes" ]]
}
# _multiselect <cur> <preselected-csv> <opt...> -> csv; rc=1 = back.
_multiselect() {
  local cur="$1" pre="$2"
  shift 2
  pick_multi "$cur" "$FOOT_MULTI" "$pre" "$@"
}
KBD="$DET_KBD" KVARIANT="" PROFILE="laptop"
USERNAME="$DET_USER" HOSTNAME="$DET_HOST"
TIMEZONE="$DET_TZ" MAINLOCALE="$DET_MAIN" REGIONAL="$DET_REGION"
# Optional app IDs (core is implicit, never stored). Migrated from any
# legacy group selection in local.nix via expandGroups.
BUNDLES=""
GITNAME="$DET_GITNAME" GITEMAIL="$DET_GITEMAIL"
CUSTOM_KBD=""
# Preserve machine flags across wizard runs: read existing local.nix
# (tablet, buildFromSource, bundles) so a re-run never silently drops them.
TABLET=0 FROMSOURCE=0
if [[ -f "$REPO/nix/machine/local.nix" ]]; then
  grep -q 'tablet *= *true' "$REPO/nix/machine/local.nix" 2>/dev/null && TABLET=1
  grep -q 'buildFromSource *= *true' "$REPO/nix/machine/local.nix" 2>/dev/null && FROMSOURCE=1
  _csv="$(cd "$REPO" && nix eval --impure --raw --expr "$DOT_CATALOG (let l = import ./nix/machine/local.nix {lib = {mkDefault = x: x;};}; in builtins.concatStringsSep \",\" (b.expandGroups (l.lysec.bundles or [])))" --extra-experimental-features 'nix-command flakes' 2>/dev/null)" \
    && [[ -n "$_csv" ]] && BUNDLES="$_csv"
fi


# _xkb_layouts: authoritative XKB list (deduped), via localectl then xkeyboard-config.
_xkb_layouts() {
  local ls=""
  ls="$(localectl list-x11-keymap-layouts 2>/dev/null)" && [[ -n "$ls" ]] || {
    local base
    for base in /run/current-system/sw/share/X11/xkb/rules /usr/share/X11/xkb/rules /etc/X11/xkb/rules; do
      [[ -f "$base/evdev.lst" ]] && { ls="$(awk '/^[[:space:]]*[a-z]{2,}/ {print $1}' "$base/evdev.lst" | grep -v '^//')"; break; }
    done
  }
  [[ -n "$ls" ]] || ls="de us gb fr es it pl cz sk hu ro si hr rs ua ru se no dk fi nl be at ch ie pt gr tr il jp kr cn tw th latam dvorak colemak workman neo bone custom"
  printf '%s\n' "$ls" | awk '!seen[$0]++'
}

step_keyboard() { # 1/4
  _rail 0
  local c ls
  ls="$(_xkb_layouts)"
  # shellcheck disable=SC2207
  local -a layouts=($ls)
  c="$(pick_filter "Keyboard layout (detected: $KBD)" "$FOOT_FILTER" "$KBD" "${layouts[@]}")" || return 1
  KBD="$c"; KVARIANT=""
  if [[ "$KBD" == "us" ]]; then
    _rail 0
    local v
    v="$(_menu "Variant" "US variant:" "${KVARIANT:-none (plain US)}" \
      "intl — international, dead keys" "altgr-intl — AltGr only" "none — plain US")" || return 1
    case "$v" in
      intl*) KVARIANT="intl" ;;
      altgr*) KVARIANT="altgr-intl" ;;
      *) KVARIANT="" ;;
    esac
  fi
}

step_bundles() { # 2/4: per-app toggles. Core always on (not offered).
  _rail 1; export _PR_STEPS _PR_INFO
  local ids
  ids="$(cd "$REPO" && nix eval --impure --raw --expr "$DOT_CATALOG builtins.concatStringsSep \" \" b.appIds" --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo "")"
  [[ -n "$ids" ]] || { ui_err "App catalog unreadable."; return 1; }
  local descs
  descs="$(cd "$REPO" && nix eval --impure --raw --expr "$DOT_CATALOG builtins.concatStringsSep \";\" (map (id: b.apps.${id}.blurb or \"\") b.appIds)" --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo "")"
  # shellcheck disable=SC2207
  local -a opts=($ids)
  PICK_DESCS="$descs"
  local csv
  csv="$(_multiselect "Software (Space toggles, Core always on)" "$BUNDLES" "${opts[@]}")"
  unset PICK_DESCS || return 1
  BUNDLES="$csv"
}

step_profile() { # 3/4
  _rail 2; export _PR_STEPS _PR_INFO
  local c
  c="$(_menu "Hardware profile (current: $PROFILE)" "Machine type:" "$PROFILE" \
    "laptop — portable quirks" \
    "desktop — no laptop quirks")" || return 1
  PROFILE="${c%% *}"
  _rail 2; export _PR_STEPS _PR_INFO
  local tdef="no"; ((TABLET == 1)) && tdef="yes"
  local t
  t="$(pick_single "Graphics tablet (XP-Pen via OpenTabletDriver)?" "$FOOT_SINGLE" "$tdef" "yes" "no")" || return 1
  [[ "$t" == "yes" ]] && TABLET=1 || TABLET=0
}

_console_for() {
  case "$1" in
    de) printf 'de' ;;
    us) printf 'us' ;;
    gb) printf 'uk' ;;
    *) printf '%s' "$1" ;;
  esac
}

_print_local_nix() { # pure render to stdout; never writes.
  local bundle_lines="" b _bs=()
  IFS=',' read -ra _bs <<<"${BUNDLES:-}"
  # drop empties + legacy "core" (implicit, never stored)
  local clean=()
  for b in ${_bs[@]+"${_bs[@]}"}; do
    [[ -z "$b" || "$b" == "core" ]] && continue
    clean+=("$b")
  done
  local last="" i=0
  for b in ${clean[@]+"${clean[@]}"}; do bundle_lines+="    \"$b\""$'\n'; done
  local tablet_str=false source_str=false
  ((TABLET == 1)) && tablet_str=true
  ((FROMSOURCE == 1)) && source_str=true
  cat <<EOF
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
    tablet = $tablet_str;
    buildFromSource = $source_str;
    bundles = [
$bundle_lines
    ];
    git.name = "$GITNAME";
    git.email = "$GITEMAIL";
  };
}
EOF
}

write_local_nix() {
  _print_local_nix >"$REPO/nix/machine/local.nix"
  printf '%sok%s local.nix: %s@%s, kbd %s/%s, profile %s\n' "$C_OK" "$C_X" "$USERNAME" "$HOSTNAME" "$KBD" "$KVARIANT" "$PROFILE" >&2
}

review_screen() { # 4/4: confirm inside fullscreen frame.
  _rail 3; export _PR_STEPS _PR_INFO
  local c
  PICK_DESCS="keyboard $KBD${KVARIANT:+/$KVARIANT};software $BUNDLES;hardware $PROFILE;system $USERNAME@$HOSTNAME"
  c="$(pick_single "Review — write local.nix, build, then switch?" "Up/Down move · Enter confirm · Esc back" "Write local.nix, build and activate" \
    "Write local.nix, build and activate" "Abort without changes")" || { unset PICK_DESCS; return 3; }
  unset PICK_DESCS
  [[ "$c" == Abort* ]] && return 2
  return 0
}

run_apply() {
  if [[ $DRY_RUN -eq 1 && $DEFAULTS -eq 1 ]]; then
    USERNAME="$USERNAME" HOSTNAME="$HOSTNAME" KBD="$KBD" KVARIANT="$KVARIANT" \
      PROFILE="$PROFILE" TIMEZONE="$TIMEZONE" MAINLOCALE="$MAINLOCALE" REGIONAL="$REGIONAL" \
      BUNDLES="$BUNDLES" GITNAME="$GITNAME" GITEMAIL="$GITEMAIL" _print_local_nix
    printf 'dry-run: local.nix NOT written, no symlinks changed, no build started.\n' >&2
    return 0
  fi
  if [[ $DEFAULTS -eq 1 ]]; then
    write_local_nix
    exec "$REPO/scripts/apply.sh"
  fi
  # fullscreen wizard with back-navigation: loop over steps.
  local s=0 rc=0
  while ((s < 4)); do
    case $s in
      0) step_keyboard && s=1 || { ((s > 0)) && s=$((s - 1)) || return 1; } ;;
      1) step_bundles && s=2 || s=0 ;;
      2) step_profile && s=3 || s=1 ;;
      3) review_screen; rc=$?; if [[ $rc -eq 0 ]]; then s=4; elif [[ $rc -eq 3 ]]; then s=2; else return 1; fi ;;
    esac
  done
  write_local_nix
  if [[ $DRY_RUN -eq 1 ]]; then
    printf 'dry-run: local.nix written; validating (no symlinks, no sudo, no build)...\n' >&2
    exec "$REPO/scripts/check.sh"
  else
    exec "$REPO/scripts/apply.sh"
  fi
}

run_apply
rc=$?
if [[ $rc -ne 0 ]]; then ui_note "Wizard exited without changes (abort or input error)."; fi
exit $rc
