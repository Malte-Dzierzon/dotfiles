#!/usr/bin/env bash
# dotfiles auto-install: nix -> symlinks -> rebuild (nh) -> user packages.
# Usage: ./scripts/install.sh [--rebuild|--no-rebuild] [--user-pkgs|--no-user-pkgs] [--desktop niri|hyprland|mango]
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REBUILD=1
USER_PKGS=1
DESKTOP=""
for a in "$@"; do
  case "$a" in
    --rebuild) REBUILD=1 ;; --no-rebuild) REBUILD=0 ;;
    --user-pkgs) USER_PKGS=1 ;; --no-user-pkgs) USER_PKGS=0 ;;
    --desktop=*) DESKTOP="${a#--desktop=}" ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "unknown: $a" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

# 1. nix-command + flakes (fresh systems without config)
if ! nix --extra-experimental-features 'nix-command flakes' flake --version >/dev/null 2>&1; then
  log "installing nix (Determinate installer)..."
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh || true
fi

# 2. optional desktop switch (writes hosts/nixos/settings.nix)
if [ -n "$DESKTOP" ]; then
  case "$DESKTOP" in
    niri|hyprland|mango)
      log "setting desktop to $DESKTOP..."
      sed -i "s/desktop = \"[a-z]*\";/desktop = \"$DESKTOP\";/" "$REPO/hosts/nixos/settings.nix"
      ;;
    *) echo "unknown desktop: $DESKTOP (niri|hyprland|mango)" >&2; exit 1 ;;
  esac
fi

# 3. link home configs (fallback until home-manager runs)
log "linking home configs..."
mkdir -p "$HOME/.config" "$HOME/.local/share"
for d in "$REPO/configs/dotconfig"/*/; do
  n=$(basename "$d")
  ln -sfn "$d" "$HOME/.config/$n"
done
ln -sfn "$REPO/home/.local/bin" "$HOME/.local/bin"
ln -sfn "$REPO/home/.local/share/applications" "$HOME/.local/share/applications"

# 4. system rebuild via flake (nh preferred, nixos-rebuild fallback)
if [ "$REBUILD" -eq 1 ]; then
  if [ -e /etc/nixos/hardware-configuration.nix ]; then
    if ! grep -q "PLACEHOLDER\|Platzhalter" "$REPO/hosts/nixos/hardware-configuration.nix" 2>/dev/null; then
      : # real config already in place
    else
      log "taking hardware-configuration from host..."
      cp /etc/nixos/hardware-configuration.nix "$REPO/hosts/nixos/hardware-configuration.nix"
    fi
  fi
  if command -v nh >/dev/null 2>&1; then
    log "nh os switch $REPO..."
    sudo nh os switch "$REPO"
  elif command -v nixos-rebuild >/dev/null 2>&1; then
    log "nixos-rebuild switch --flake $REPO#nixos..."
    sudo nixos-rebuild switch --flake "$REPO#nixos"
  else
    warn "neither nh nor nixos-rebuild found"
    exit 1
  fi
fi

# 5. per-user packages (flakes, not system-wide)
if [ "$USER_PKGS" -eq 1 ]; then
  log "user packages..."
  nix profile install "github:youwen5/zen-browser-flake" 2>/dev/null || warn "zen-browser-flake skipped"
fi

log "done. reboot recommended after bootloader/kernel change."
