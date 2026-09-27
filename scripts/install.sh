#!/usr/bin/env bash
# Symlinkt home-Configs; System-Teil siehe README.
set -euo pipefail
DOT="$HOME/Projects/dotfiles/home/.config"
for d in "$DOT"/*/; do
  n=$(basename "$d")
  case "$n" in niri|noctalia|fish) ln -sfn "$d" "$HOME/.config/$n" ;;
    *) echo "skip: $n (erst prüfen)" ;; esac
done
echo "OK. Neues Gerät: nixos/configuration.nix nach /etc/nixos/ kopieren + rebuild."
