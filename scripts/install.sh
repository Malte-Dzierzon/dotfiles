#!/usr/bin/env bash
# dotfiles auto-install: Flake-Rebuild + Home-Manager-Symlinks + per-user Pakete.
# Aufruf: ./scripts/install.sh [--rebuild|--no-rebuild] [--user-pkgs|--no-user-pkgs]
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REBUILD=1
USER_PKGS=1
for a in "$@"; do
  case "$a" in
    --rebuild) REBUILD=1 ;; --no-rebuild) REBUILD=0 ;;
    --user-pkgs) USER_PKGS=1 ;; --no-user-pkgs) USER_PKGS=0 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unbekannt: $a" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

# 1. nix-command + flakes sicherstellen (für frische Systeme ohne Config)
if ! nix --extra-experimental-features 'nix-command flakes' flake --version >/dev/null 2>&1; then
  log "installiere nix (Determinate-Installer)…"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh || true
fi

# 2. Home-Configs verlinken (Fallback falls home-manager noch nicht läuft)
log "verlinke home-configs…"
mkdir -p "$HOME/.config" "$HOME/.local/share"
for d in "$REPO/home/.config"/*/; do
  n=$(basename "$d")
  case "$n" in
    niri|noctalia|fish|hypr|mango|foot|ghostty|walker|elephant|fastfetch|starship|bat|zed|nvim|git|gh|lazygit|tmux|btop|yazi|imv|mpv|zathura|gtk-3.0|gtk-4.0|mimeapps.list|xdg-desktop-portal)
      ln -sfn "$d" "$HOME/.config/$n" ;;
    *) warn "skip ~/.config/$n (erst prüfen: ln -sfn '$d' '\$HOME/.config/$n')" ;;
  esac
done
ln -sfn "$REPO/home/.local/bin" "$HOME/.local/bin"
ln -sfn "$REPO/home/.local/share/applications" "$HOME/.local/share/applications"
fish_add_path() { :; } # no-op falls fish fehlt

# 3. System-Rebuild via Flake (inkl. home-manager)
if [ "$REBUILD" -eq 1 ]; then
  if [ -e /etc/nixos/hardware-configuration.nix ] && [ ! -e "$REPO/hosts/nixos/hardware-configuration.nix" ]; then
    log "übernehme hardware-configuration vom Host…"
    cp /etc/nixos/hardware-configuration.nix "$REPO/hosts/nixos/hardware-configuration.nix"
  fi
  if command -v nixos-rebuild >/dev/null 2>&1; then
    log "nixos-rebuild switch --flake $REPO#nixos…"
    sudo nixos-rebuild switch --flake "$REPO#nixos"
  elif [ "$(uname -s)" = "Darwin" ] || ! [ -e /etc/NIXOS ]; then
    warn "kein NixOS — nur home-manager-Standalone"
    nix run home-manager/release-26.05 -- switch --flake "$REPO#xealom@$(hostname)"
  else
    warn "nixos-rebuild fehlt"
    exit 1
  fi
fi

# 4. per-user Pakete (Flakes, nicht im System)
if [ "$USER_PKGS" -eq 1 ]; then
  log "user-pakete…"
  nix profile install "github:youwen5/zen-browser-flake" 2>/dev/null || warn "zen-browser-flake übersprungen"
fi

log "fertig. reboot empfohlen bei neuem Bootloader/Kernel."
