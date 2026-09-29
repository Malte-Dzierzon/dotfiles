#!/usr/bin/env bash
# Ein-Zeilen-Bootstrap für ein frisches NixOS:
#   curl -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/main/scripts/bootstrap.sh | bash
set -euo pipefail
REPO_URL="https://github.com/Malte-Dzierzon/dotfiles.git"
DEST="$HOME/Projects/dotfiles"
command -v git >/dev/null || nix-shell -p git --run "true" 2>/dev/null || {
  echo "git fehlt und nix-shell geht nicht — git manuell installieren"; exit 1; }
[ -d "$DEST/.git" ] || git clone "$REPO_URL" "$DEST"
exec "$DEST/scripts/install.sh" "$@"
