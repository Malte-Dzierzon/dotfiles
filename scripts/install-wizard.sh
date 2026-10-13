#!/usr/bin/env bash
# install-wizard.sh — interactive, keyboard-driven installer.
#
# Modes:
#   install-wizard.sh --apply   installed NixOS: TUI -> local.nix -> validate -> rebuild
#   install-wizard.sh --check   reserved (currently no-op; apply.sh uses lib.sh preflights directly)
#
# TUI: gum if present (progressive enhancement), else dialog, else pure-bash
# numbered menus. All three work over plain TTYSSH with keyboard only.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

MODE="--apply"
DRY_RUN=0
for _a in "$@"; do [[ "$_a" == "--dry-run" ]] && DRY_RUN=1; done
HAVE_GUM=0 HAVE_DIALOG=0
command -v gum >/dev/null 2>&1 && HAVE_GUM=1
command -v dialog >/dev/null 2>&1 && HAVE_DIALOG=1
# Real TTY check via open probe (-r/-c lie under pipes/CI).
HAVE_TTY=0
{ : </dev/tty; } 2>/dev/null && HAVE_TTY=1

# --- tiny TUI layer ---------------------------------------------------------
# _menu <title> <prompt> <default> <opt...> -> prints choice to stdout.
# Back/cancel: empty output + return 1.
_menu() {
  local title="$1" prompt="$2" def="$3"
  shift 3
  local opts=("$@") i choice=""
  # _tty_read: prefer /dev/tty, stdin as fallback (pipes/tests).
  _tty_read() {
    if [[ $HAVE_TTY -eq 1 ]] && IFS= read -r "$1" </dev/tty 2>/dev/null; then return 0; fi
    IFS= read -r "$1" || return 1
  }
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then
    choice="$(gum choose --header "$title — $prompt (Esc = back)" --selected "$def" "${opts[@]}" </dev/tty 2>/dev/null)" && [[ -n "$choice" ]] && {
      printf '%s' "$choice"
      return 0
    }
    # gum present but no TTY (pipe/CI) — fall back to text menu instead of silently aborting.
  fi
  if [[ $HAVE_DIALOG -eq 1 && $HAVE_TTY -eq 1 ]]; then
    local args=() n=0
    for o in "${opts[@]}"; do
      n=$((n + 1))
      if [[ "$o" == "$def" ]]; then args+=("$n" "$o" "on"); else args+=("$n" "$o" "off"); fi
    done
    # dialog: UI -> /dev/tty, choice (stderr) -> capture. Ordering is intentional (SC2327/2328 exception).
    # shellcheck disable=SC2327,SC2328
    choice="$(dialog --clear --backtitle "dotfiles installer" --title "$title" \
      --radiolist "$prompt (Cancel = back)" 16 60 "$n" "${args[@]}" 2>&1 >/dev/tty </dev/tty)" && [[ -n "$choice" ]] && {
      printf '%s' "${opts[$((choice - 1))]}"
      return 0
    }
  fi
  _bash_menu() {
    printf '\n=== %s ===\n%s\n' "$title" "$prompt" >&2
    i=0
    for o in "${opts[@]}"; do
      i=$((i + 1))
      if [[ "$o" == "$def" ]]; then printf '  %d) %s  [default]\n' "$i" "$o" >&2; else printf '  %d) %s\n' "$i" "$o" >&2; fi
    done
    printf '  0) back\nChoice [default=%s]: ' "$def" >&2
    _tty_read choice || return 1
    if [[ -z "$choice" ]]; then printf '%s' "$def"; return 0; fi
    if [[ "$choice" == "0" ]]; then return 1; fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#opts[@]})); then
      printf '%s' "${opts[$((choice - 1))]}"
      return 0
    fi
    return 1
  }
  _bash_menu
}

# _ask <title> <prompt> <default> -> prints answer; empty keeps default.
_ask() {
  local title="$1" prompt="$2" def="$3" ans=""
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then
    ans="$(gum input --header "$title" --prompt "$prompt " --value "$def" </dev/tty 2>/dev/null)" && {
      printf '%s' "${ans:-$def}"
      return 0
    }
  fi
  printf '\n=== %s ===\n%s [default=%s]: ' "$title" "$prompt" "$def" >&2
  if [[ $HAVE_TTY -eq 1 ]] && IFS= read -r ans </dev/tty 2>/dev/null; then :; else IFS= read -r ans || return 1; fi
  printf '%s' "${ans:-$def}"
}

# _confirm <text> -> return 0 on yes.
_confirm() {
  local text="$1" ans=""
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then
    gum confirm "$text" </dev/tty 2>/dev/null
    return $?
  fi
  if [[ $HAVE_DIALOG -eq 1 && $HAVE_TTY -eq 1 ]]; then
    dialog --clear --backtitle "dotfiles installer" --yesno "$text" 10 60 >/dev/tty 2>&1 </dev/tty
    return $?
  fi
  printf '%s [y/N]: ' "$text" >&2
  if [[ $HAVE_TTY -eq 1 ]] && IFS= read -r ans </dev/tty 2>/dev/null; then :; else IFS= read -r ans || return 1; fi
  [[ "$ans" == [yYjJ]* ]]
}

# _multiselect <title> <prompt> <preselected-csv> <opt...> -> prints csv.
_multiselect() {
  local title="$1" prompt="$2" pre="$3"
  shift 3
  local opts=("$@") out=""
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then
    local args=()
    for o in "${opts[@]}"; do
      if [[ ",$pre," == *",$o,"* ]]; then args+=("--selected=$o"); fi
    done
    if out="$(gum choose --no-limit --header "$title — $prompt (Space = toggle, Enter = ok)" "${args[@]}" "${opts[@]}" </dev/tty 2>/dev/null)" && [[ -n "$out" ]]; then
      printf '%s' "$out" | tr '\n' ',' | sed 's/,$//'
      return 0
    fi
  fi
  printf '\n=== %s ===\n%s\nNumbers, comma-separated (e.g. 1,3,4), 0 = back:\n' "$title" "$prompt" >&2
  local i=0
  for o in "${opts[@]}"; do
    i=$((i + 1))
    if [[ ",$pre," == *",$o,"* ]]; then printf '  %d) [x] %s\n' "$i" "$o" >&2; else printf '  %d) [ ] %s\n' "$i" "$o" >&2; fi
  done
  printf 'Choice: ' >&2
  local raw sel=() n
  if [[ $HAVE_TTY -eq 1 ]] && IFS= read -r raw </dev/tty 2>/dev/null; then :; else IFS= read -r raw || return 1; fi
  [[ "$raw" == "0" ]] && return 1
  IFS=',' read -ra sel <<<"$raw"
  out=""
  for n in "${sel[@]}"; do
    n="${n// /}"
    [[ "$n" =~ ^[0-9]+$ ]] && ((n >= 1 && n <= ${#opts[@]})) || return 1
    out+="${opts[$((n - 1))]},"
  done
  printf '%s' "${out%,}"
}

# --- collected answers (defaults = current settings.nix) --------------------
_step() { printf "\n[%s] %s\n" "$1" "$2" >&2; }
_banner() {
  local backend="text menu (bash)"
  [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]] && backend="gum"
  [[ $HAVE_DIALOG -eq 1 && $backend == "text menu (bash)" && $HAVE_TTY -eq 1 ]] && backend="dialog"
  cat >&2 <<EOF
=== dotfiles installer ($MODE, rev $(dot_rev), UI: $backend) ===
Keyboard: choose de/us/gb — applies to console + XKB + greeter + Umbriel.
0 or Esc = step back/abort. NOTHING is changed until the
final confirmation (review screen).
EOF
}
KBD="de" KVARIANT="" PROFILE="laptop" USERNAME="xealom" HOSTNAME="nixos"
TIMEZONE="Europe/Berlin" MAINLOCALE="en_US.UTF-8" REGIONAL="de_DE.UTF-8"
BUNDLES="core,terminal,editor,desktop,browser,dev,latex,notes,media,gaming,chat,net,fun"
GITNAME="Malte Dzierzon" GITEMAIL="malte@dzierzon.example"
CUSTOM_KBD=""

ALL_BUNDLES=(core terminal editor desktop browser dev latex notes media gaming chat net fun)

step_keyboard() {
  local c
  c="$(_menu "Keyboard" "Choose physical layout:" "$KBD" \
    "de — German QWERTZ" "us — US English QWERTY" "gb — UK English QWERTY" "custom — other (xkbcli name)")" || return 1
  case "$c" in
    de*) KBD="de" ;;
    us*) KBD="us" ;;
    gb*) KBD="gb" ;;
    custom*)
      CUSTOM_KBD="$(_ask "Keyboard" "XKB layout name (xkbcli name, e.g. fr, neo):" "fr")" || return 1
      KBD="$CUSTOM_KBD"
      _dot_warn "Custom layout: assuming console keymap = XKB name. On divergence adjust local.nix (consoleKeyMap)."
      ;;
  esac
  if [[ "$KBD" == "us" ]]; then
    local v
    v="$(_menu "Keyboard variant" "Choose US variant:" "${KVARIANT:-none (plain US)}" \
      "intl — US international with dead keys" "altgr-intl — AltGr only, no dead keys" "none — plain US")" || return 1
    case "$v" in
      intl*) KVARIANT="intl" ;;
      altgr*) KVARIANT="altgr-intl" ;;
      *) KVARIANT="" ;;
    esac
  else
    KVARIANT=""
  fi
}

step_profile() {
  local c
  c="$(_menu "Profile" "Machine type (controls quirks only, never hardware detection):" "$PROFILE" \
    "laptop — eDP panel, intel_vbtn quirk, powersaving" \
    "desktop — no laptop quirks, external outputs")" || return 1
  PROFILE="${c%% *}"
}

step_identity() {
  USERNAME="$(_ask "Identity" "Username:" "$USERNAME")" || return 1
  HOSTNAME="$(_ask "Identity" "Hostname:" "$HOSTNAME")" || return 1
  TIMEZONE="$(_ask "Identity" "Timezone (IANA, e.g. Europe/Berlin):" "$TIMEZONE")" || return 1
  MAINLOCALE="$(_ask "Identity" "System locale (i18n.defaultLocale):" "$MAINLOCALE")" || return 1
  REGIONAL="$(_ask "Identity" "Regional LC_* bundle:" "$REGIONAL")" || return 1
  GITNAME="$(_ask "Identity" "Git user.name:" "$GITNAME")" || return 1
  GITEMAIL="$(_ask "Identity" "Git user.email:" "$GITEMAIL")" || return 1
  [[ "$USERNAME" =~ ^[a-z][a-z0-9_-]*$ ]] || {
    _dot_warn "Username '$USERNAME' is invalid (lowercase, [a-z0-9_-])."
    return 1
  }
  # Hostname (short RFC 1035): otherwise Nix writes an invalid networking.hostName.
  [[ "$HOSTNAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || {
    _dot_warn "Hostname '$HOSTNAME' is invalid (lowercase, alphanumeric, inner hyphens)."
    return 1
  }
  # Nix injection guard: no ", \, $ in free text (local.nix string literals).
  local f
  for f in HOSTNAME TIMEZONE MAINLOCALE REGIONAL GITNAME GITEMAIL; do
    [[ "${!f}" != *['"'\$]* ]] || {
      _dot_warn "Invalid character in $f (no \", \\, \$ allowed)."
      return 1
    }
  done
  # Validate timezone against zoneinfo when readable (ISO/NixOS: /usr/share/zoneinfo).
  if [[ -d /usr/share/zoneinfo && ! -e "/usr/share/zoneinfo/$TIMEZONE" ]]; then
    _dot_warn "Timezone '$TIMEZONE' not found in /usr/share/zoneinfo."
    return 1
  fi
}

step_bundles() {
  local csv
  csv="$(_multiselect "Applications" "Choose bundles (shell+greeter always on):" "$BUNDLES" "${ALL_BUNDLES[@]}")" || return 1
  [[ -z "$csv" ]] && {
    _dot_warn "Choose at least one bundle (core recommended)."
    return 1
  }
  BUNDLES="$csv"
}

# console keymap mapping (single place; mirrors modules/lysec/options.nix).
_console_for() {
  case "$1" in
    de) printf 'de' ;;
    us) printf 'us' ;;
    gb) printf 'uk' ;;
    *) printf '%s' "$1" ;;
  esac
}

# write local.nix from answers (generated category; never committed).
write_local_nix() {
  local bundle_lines b
  bundle_lines=""
  IFS=',' read -ra _bs <<<"$BUNDLES"
  local last="${_bs[${#_bs[@]}-1]}"
  for b in "${_bs[@]}"; do bundle_lines+="    \"$b\""; [[ "$b" != "$last" ]] && bundle_lines+=$'\n'; done
  cat >"$REPO/hosts/nixos/local.nix" <<EOF
# Generated by scripts/install-wizard.sh ($MODE) on $(date -u +%F) — per machine, git-ignored.
# Change: edit file + scripts/apply.sh. Upstream updates never touch this file (git-ignored).
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
  _dot_ok "local.nix written (keyboard $KBD/$KVARIANT, console $(_console_for "$KBD"), profile $PROFILE)."
}

review_screen() {
  cat >&2 <<EOF

================ INSTALL PLAN ================
  Modus:      $MODE
  Revision:   $(dot_rev)
  Keyboard: $KBD/$KVARIANT (XKB) / $(_console_for "$KBD") (console) — applies to kernel, XKB, greeter, Umbriel (follows system)
  Profile:  $PROFILE
  User@Host:  $USERNAME@$HOSTNAME
  Timezone: $TIMEZONE
  Locales:    $MAINLOCALE / $REGIONAL
  Bundles:    $BUNDLES
  Git:        $GITNAME <$GITEMAIL>
EOF
  echo "  Effect:     write local.nix, dry-build, then nixos-rebuild switch" >&2
  echo "==================================================" >&2
}

# --- run --apply ---
run_apply() {
  _banner
  step_keyboard || return 1
  step_profile || return 1
  step_identity || return 1
  step_bundles || return 1
  review_screen
  _confirm "Write local.nix and activate $REPO#nixos via nixos-rebuild?" || {
    _dot_warn "Aborted — nothing written, nothing rebuilt."
    return 1
  }
  write_local_nix
  if [[ $DRY_RUN -eq 1 ]]; then exec "$REPO/scripts/apply.sh" --dry-run; else exec "$REPO/scripts/apply.sh"; fi
}

case "$MODE" in
  --apply) run_apply ;;
  *) echo "usage: $0 [--apply]" >&2; exit 1 ;;
esac
rc=$?
if [[ $rc -ne 0 ]]; then
  _dot_warn "Wizard exited without changes (abort or input error)."
fi
exit $rc
