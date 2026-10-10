#!/usr/bin/env bash
# update.sh — Mode 3: explicit repository + input updates. Changes NOTHING
# live; applying is always a separate `./scripts/apply.sh` run.
#
#   ./scripts/update.sh [--check] [--pull] [--inputs] [--dry-run]
#
#   --check    fetch + show what WOULD change (repo + flake inputs), no writes
#   --pull     fetch + rebase/merge remote main (refuses dirty tree)
#   --inputs   nix flake update (unpins upstream inputs deliberately)
#   (no flag = --check)
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
# shellcheck source=ui.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ui.sh"

DO_CHECK=0 DO_PULL=0 DO_INPUTS=0 DRY_RUN=0
[[ $# -eq 0 ]] && DO_CHECK=1
for a in "$@"; do
  case "$a" in
    --check) DO_CHECK=1 ;;
    --pull) DO_PULL=1 ;;
    --inputs) DO_INPUTS=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h | --help) sed -n '2,11p' "$0"; exit 0 ;;
    *)
      echo "unknown: $a" >&2
      exit 1
      ;;
  esac
done

run() {
  if [[ $DRY_RUN -eq 1 ]]; then echo "dry-run: $*"; else "$@"; fi
}

cd "$REPO"
BEFORE="$(dot_current_rev)"
ui_head "repo-stand"

_dot_log "fetch origin..."
run git fetch origin || {
  echo "XX fetch fehlgeschlagen (offline?)." >&2
  exit 1
}

if [[ $DO_CHECK -eq 1 || $DO_PULL -eq 0 && $DO_INPUTS -eq 0 ]]; then
  echo "--- remote main vs lokal ---"
  git log --oneline "$BEFORE..origin/main" -- 2>/dev/null | head -n 30 || true
  if git diff --quiet "$BEFORE" origin/main -- . 2>/dev/null; then
    _dot_ok "Repo aktuell."
  else
    _dot_warn "Updates verfuegbar — mit --pull holen, dann DIFF reviewen, dann apply.sh."
  fi
  echo "--- flake inputs (gepinnt, Stand) ---"
  git log --oneline -1 -- flake.lock
  nix flake metadata 2>/dev/null | grep -E '^\s+(nixpkgs|home-manager|umbriel|noctalia|zen-browser|toofan|concord|sonora):' | head -n 10 || true
fi

if [[ $DO_PULL -eq 1 ]]; then
  dot_repo_clean
ui_head "pull"
  run git pull --ff-only origin main || {
    echo "XX pull nicht fast-forward (divergiert) — manuell rebasen, nichts geaendert ausser fetch." >&2
    exit 1
  }
  echo "--- was sich geaendert hat (reviewen!) ---"
  git log --oneline "$BEFORE..HEAD" -- | head -n 30
  git diff --stat "$BEFORE..HEAD" -- | tail -n 20
  _dot_warn "Noch NICHT aktiv. Anwenden: ./scripts/apply.sh"
fi

if [[ $DO_INPUTS -eq 1 ]]; then
ui_head "flake-inputs"
  _dot_warn "nix flake update loest ALLE Upstream-Pins — danach flake.lock reviewen + apply.sh --dry-run."
  if [[ $DRY_RUN -eq 0 ]] && ! _confirm_update; then
    echo "abgebrochen." >&2
    exit 1
  fi
  run nix flake update
  run git diff --stat -- flake.lock
fi

_confirm_update() {
  local ans
  printf 'WIRKLICH alle Flake-Inputs updaten? [y/N]: ' >&2
  IFS= read -r ans || return 1
  [[ "$ans" == [yY]* ]]
}
