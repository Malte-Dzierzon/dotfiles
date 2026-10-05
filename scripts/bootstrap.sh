#!/usr/bin/env bash
# One-line bootstrap for a fresh NixOS:
#   curl -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/<ref>/scripts/bootstrap.sh | bash
# Pin <ref> to a commit for reproducibility; `main` floats.
set -euo pipefail
REPO_URL="https://github.com/Malte-Dzierzon/dotfiles.git"
DEST="${DEST:-$HOME/Projects/dotfiles}"
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only
else
  git clone "$REPO_URL" "$DEST"
fi
exec "$DEST/scripts/install.sh" "$@"
