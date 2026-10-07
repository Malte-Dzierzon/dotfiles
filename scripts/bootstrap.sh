#!/usr/bin/env bash
# One-line bootstrap for a fresh NixOS:
#   curl -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/<ref>/scripts/bootstrap.sh | bash
# Pin <ref> to a commit for reproducibility; `main` floats.
set -euo pipefail
REPO_URL="https://github.com/Malte-Dzierzon/dotfiles.git"
DEST="${DEST:-$HOME/Projects/dotfiles}"
command -v git >/dev/null 2>&1 || { echo "git fehlt (z.B. nix-shell -p git) - aborting" >&2; exit 1; }
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only || echo "pull fehlgeschlagen (dirty worktree?) - fahre mit lokalem Stand fort" >&2
else
  git clone "$REPO_URL" "$DEST"
fi
exec "$DEST/scripts/install.sh" "$@"
