#!/usr/bin/env bash
# install.sh — Kompatibilitaets-Shim (altes Interface, neue Modi).
# Neue Befehle: apply.sh (Modus 2), update.sh (Modus 3), live-installer.sh
# (Modus 1), install-wizard.sh (TUI), verify.sh (Modus 4).
# Mapping: --verify-only -> verify.sh; --wizard -> TUI; Rest -> apply.sh.
# --(no-)user-pkgs ausgemustert (warn-only Externals) — akzeptiert, kein Effekt.
# Faehrt auf Live-ISO/Arch NICHT fort (apply.sh preflight), baut NIE ohne
# dry-build (apply.sh), stagt Hardware-Config nur per trap (lib.sh).
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGS=()
for a in "$@"; do
  case "$a" in
    --verify-only) exec "$REPO/scripts/verify.sh" ;;
    --wizard) exec "$REPO/scripts/install-wizard.sh" --apply ;;
    --rebuild) ARGS+=() ;; # default in apply.sh
    --no-rebuild) ARGS+=(--no-rebuild) ;;
    # --(no-)user-pkgs ausgemustert: Externals sind warn-only in apply.sh,
    # es gibt nichts mehr zu (de-)aktivieren — akzeptiert, kein Effekt.
    --user-pkgs) ARGS+=() ;;
    --no-user-pkgs) ARGS+=() ;;
    --dry-run) ARGS+=(--dry-run) ;;
    -h | --help)
      echo "usage: install.sh [--dry-run|--no-rebuild|--wizard|--verify-only]"
      echo "  --(no-)user-pkgs akzeptiert, ohne Effekt (ausgemustert)"
      echo "  (Shim: ruft apply.sh / install-wizard.sh / verify.sh)"
      exit 0
      ;;
    *)
      echo "unknown: $a" >&2
      exit 1
      ;;
  esac
done
echo ":: install.sh ist ein Shim — neue Modi: apply.sh, update.sh, live-installer.sh, verify.sh" >&2
exec "$REPO/scripts/apply.sh" "${ARGS[@]}"
