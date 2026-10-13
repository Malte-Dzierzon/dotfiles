#!/usr/bin/env bash
# install.sh — compatibility shim (old interface, new commands).
# New commands: apply.sh, apps.sh, sync.sh, install-wizard.sh --apply, verify.sh.
# Mapping: --verify-only -> verify.sh; --wizard -> TUI; rest -> apply.sh.
# --(no-)user-pkgs retired (warn-only externals) — accepted, no effect.
# Does NOT proceed on Arch (apply.sh preflight), NEVER builds without
# dry-build (apply.sh), stages hardware config only via trap (lib.sh).
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGS=()
for a in "$@"; do
  case "$a" in
    --verify-only) exec "$REPO/scripts/verify.sh" ;;
    --wizard) exec "$REPO/scripts/install-wizard.sh" --apply ;;
    --rebuild) ARGS+=() ;; # default in apply.sh
    --no-rebuild) ARGS+=(--no-rebuild) ;;
    # --(no-)user-pkgs retired: externals are warn-only in apply.sh,
    # there is nothing left to (de)activate — accepted, no effect.
    --user-pkgs) ARGS+=() ;;
    --no-user-pkgs) ARGS+=() ;;
    --dry-run) ARGS+=(--dry-run) ;;
    -h | --help)
      echo "usage: install.sh [--dry-run|--no-rebuild|--wizard|--verify-only]"
      echo "  --(no-)user-pkgs accepted, no effect (retired)"
      echo "  (shim: calls apply.sh / install-wizard.sh / verify.sh)"
      exit 0
      ;;
    *)
      echo "unknown: $a" >&2
      exit 1
      ;;
  esac
done
echo ":: install.sh is a shim — new commands: apply.sh, apps.sh, sync.sh, verify.sh" >&2
exec "$REPO/scripts/apply.sh" "${ARGS[@]}"
