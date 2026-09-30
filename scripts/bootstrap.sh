#!/usr/bin/env bash
# One-line bootstrap for a fresh NixOS:
#   curl -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/main/scripts/bootstrap.sh | bash
set -euo pipefail
REPO_URL="https://github.com/Malte-Dzierzon/dotfiles.git"
DEST="$HOME/Projects/dotfiles"
command -v git >/dev/null || nix-shell -p git --run "true" 2>/dev/null || {
  echo "git missing and nix-shell failed - install git manually"; exit 1; }
[ -d "$DEST/.git" ] || git clone "$REPO_URL" "$DEST"
exec "$DEST/scripts/install.sh" "$@"
