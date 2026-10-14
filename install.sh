#!/usr/bin/env bash
# install.sh — staged installer entry: checks -> wizard -> apply.
# Runs as USER (never sudo ./install.sh); only nixos-rebuild escalates.
# Nothing is written before the wizard's review screen confirms.
# Usage: ./install.sh [--dry-run]   (dry-run: local.nix only after review confirm, then check only — no symlinks/sudo/build)
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$REPO/scripts/lib.sh"
if [[ "${EUID}" -eq 0 ]]; then
  _dot_err "Do not run as root — run as your user; sudo is used only for activation."
  exit 1
fi

echo "dotfiles installer — 4 stages: checks, configure, review, install."
echo "Nothing is written or activated until you confirm the review screen."
echo ""

echo "[1/4] environment checks"
fails=0
command -v nix >/dev/null 2>&1 || { _dot_err "nix missing."; fails=1; }
dot_on_nixos || { _dot_err "Not NixOS ($(grep -oP '^PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || uname -s)) — install NixOS first."; fails=1; }
if dot_on_live_iso; then
  _dot_err "Live ISO: this installer targets an installed system, not RAM."
  fails=1
fi
if [[ -e "$REPO/nix/machine/local.nix" ]]; then
  _dot_warn "nix/machine/local.nix exists — wizard will show its values; confirm before overwrite."
fi
if [[ ! -s "$REPO/nix/machine/hardware-configuration.nix" ]]; then
  if [[ -f /etc/nixos/hardware-configuration.nix ]]; then
    _dot_log "hardware config will be adopted from /etc/nixos (validated)."
  else
    _dot_err "No hardware config (repo or /etc/nixos) — run nixos-generate-config first."
    fails=1
  fi
fi
[[ $fails -eq 0 ]] || exit 1
_dot_ok "environment ok"

echo "[2/4] configure (wizard)"
if [[ "${1:-}" == "--dry-run" ]]; then
  _dot_warn "--dry-run: local.nix only after review confirm, then validation only (no symlinks/sudo/build)."
  "$REPO/scripts/install-wizard.sh" --apply --dry-run
else
  "$REPO/scripts/install-wizard.sh" --apply
fi
