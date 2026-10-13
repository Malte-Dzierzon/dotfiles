#!/usr/bin/env bash
# restore.sh — inspect and roll back NixOS system generations (native mechanism).
# Usage: restore.sh [--dry-run] [N]
#   no args: list generations, mark current, prompt to pick one (no action yet).
#   N: show generation N detail, require explicit confirm, then roll back.
#   --dry-run: print what WOULD run, activate nothing (for tests/preview).
# Never touches editable source files or app settings — system only.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
source "$REPO/scripts/lib.sh"

DRY_RUN=0 WANT=""
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN=1 ;;
    -h | --help) sed -n '2,7p' "$0"; exit 0 ;;
    *) WANT="$a" ;;
  esac
done

PROFILE=/nix/var/nix/profiles/system
run() { if [[ $DRY_RUN -eq 1 ]]; then echo "dry-run: $*"; else "$@"; fi }

current() { readlink "$PROFILE" 2>/dev/null || echo "?"; }

if [[ -z "$WANT" ]]; then
  echo "System generations (current: $(current)):"
  nix-env --list-generations -p "$PROFILE" 2>/dev/null || sudo nix-env --list-generations -p "$PROFILE" 2>/dev/null || { _dot_err "cannot list generations (need sudo?)."; exit 1; }
  echo ""
  echo "Rollback restores the SYSTEM only — not ~/dot2 sources, ~/.config, or ~/.local/state."
  printf 'Generation number to inspect (empty = quit): '
  IFS=read -r WANT || exit 0
  [[ -z "$WANT" ]] && exit 0
fi

[[ "$WANT" =~ ^[0-9]+$ ]] || { _dot_err "not a generation number: $WANT"; exit 2; }
LINK="$PROFILE-${WANT}-link"
[[ -e "$LINK" ]] || { _dot_err "no such generation: $LINK"; exit 1; }

echo "Selected: $LINK -> $(readlink "$LINK")"
echo "Date:     $(stat -c %y "$LINK" 2>/dev/null || echo ?)"
if [[ "$(readlink "$LINK")" == "$(current)" ]]; then
  echo "This IS the current generation — nothing to do."
  exit 0
fi
echo ""
echo "This activates generation $WANT (native switch-to-configuration)."
echo "Source files and app settings stay as they are."
if [[ $DRY_RUN -eq 1 ]]; then
  run sudo "$LINK/bin/switch-to-configuration" switch
  exit 0
fi
printf 'Roll back to generation %s now? [y/N]: ' "$WANT"
IFS= read -r ans || exit 1
[[ "$ans" == [yYjJ]* ]] || { echo "aborted."; exit 1; }
run sudo "$LINK/bin/switch-to-configuration" switch
