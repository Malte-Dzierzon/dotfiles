#!/usr/bin/env bash
# dotfiles auto-install: nix -> symlinks -> rebuild (nh) -> user packages.
# Usage: ./scripts/install.sh [--rebuild|--no-rebuild] [--user-pkgs|--no-user-pkgs] [--desktop niri|umbriel|hyprland|mango]
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
    niri|umbriel|hyprland|mango)
      log "setting desktop to $DESKTOP..."
      sed -i "s/desktop = \"[a-z]*\";/desktop = \"$DESKTOP\";/" "$REPO/hosts/nixos/settings.nix"
      ;;
    *) echo "unknown desktop: $DESKTOP (niri|umbriel|hyprland|mango)" >&2; exit 1 ;;
  esac
fi

# 3. link home configs (fallback until home-manager runs; mirrors home-entry.nix:
#    every dir in configs/dotconfig becomes ~/.config/<dir>, except starship/
#    (file -> ~/.config/starship.toml) and mimeapps.list (file, not dir))
link() { # link <src> <dst>: ersetzt Datei/Symlink/Verzeichnis idempotent (Backup bei Real-Dir)
  local src="$1" dst="$2"
  [ -e "$dst" ] && [ ! -L "$dst" ] && [ -d "$dst" ] && { mv "$dst" "$dst.pre-dotfiles"; warn "backup: $dst -> $dst.pre-dotfiles"; }
  ln -sfn "$src" "$dst"
}
log "linking home configs..."
mkdir -p "$HOME/.config" "$HOME/.local/share"
for d in "$REPO/configs/dotconfig"/*/; do
  n=$(basename "$d")
  case "$n" in
    starship) link "$d/starship.toml" "$HOME/.config/starship.toml" ;;
    mimeapps.list) : ;; # file, handled below
    *) link "$d" "$HOME/.config/$n" ;;
  esac
done
[ -f "$REPO/configs/dotconfig/mimeapps.list" ] && link "$REPO/configs/dotconfig/mimeapps.list" "$HOME/.config/mimeapps.list"
link "$REPO/home/.local/bin" "$HOME/.local/bin"
link "$REPO/home/.local/share/applications" "$HOME/.local/share/applications"

# 4. system rebuild via flake (nh preferred, nixos-rebuild fallback)
if [ "$REBUILD" -eq 1 ]; then
  HW="$REPO/hosts/nixos/hardware-configuration.nix"
  if [ ! -s "$HW" ] && [ -e /etc/nixos/hardware-configuration.nix ]; then
    log "taking hardware-configuration from host..."
    cp /etc/nixos/hardware-configuration.nix "$HW"
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

# 5. per-user packages (flakes, not system-wide) + externe Binaries
#    (nicht in nixpkgs: omp, cliamp+cliamp-real, zapfast+zapfast-real,
#    pakmc-bin — je Rechner neu laden, daher nicht im Repo)
if [ "$USER_PKGS" -eq 1 ]; then
  log "user packages..."
  nix profile install "github:youwen5/zen-browser-flake" 2>/dev/null || warn "zen-browser-flake skipped"
  need_bin() { [ -x "$HOME/.local/bin/$1" ]; }
  need_bin omp && need_bin cliamp-real && need_bin zapfast-real && need_bin pakmc-bin \
    || warn "externe Binaries fehlen (~/.local/bin/{omp,cliamp-real,zapfast-real,pakmc-bin}) — manuell nachladen, .desktop-Dateien erwarten sie dort"
fi

log "done. reboot recommended after bootloader/kernel change."
