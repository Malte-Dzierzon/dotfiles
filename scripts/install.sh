#!/usr/bin/env bash
# dotfiles auto-install: nix -> symlinks -> rebuild (nh) -> user packages.
# Usage: ./scripts/install.sh [--rebuild|--no-rebuild] [--user-pkgs|--no-user-pkgs] [--dry-run] [--verify-only]
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REBUILD=1
USER_PKGS=1
DRY_RUN=0
VERIFY_ONLY=0
for a in "$@"; do
  case "$a" in
    --rebuild) REBUILD=1 ;; --no-rebuild) REBUILD=0 ;;
    --user-pkgs) USER_PKGS=1 ;; --no-user-pkgs) USER_PKGS=0 ;;
    --dry-run) DRY_RUN=1 ;;
    --verify-only) VERIFY_ONLY=1 ;;
    -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
    *) echo "unknown: $a" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
run() { if [ "$DRY_RUN" -eq 1 ]; then echo "dry-run: $*"; else "$@"; fi; }

if [ "$VERIFY_ONLY" -eq 1 ]; then exec "$REPO/scripts/verify.sh"; fi

# 1. nix-command + flakes (fresh systems without config)
if ! nix --extra-experimental-features 'nix-command flakes' flake --version >/dev/null 2>&1; then
  log "installing nix (Determinate installer)..."
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "dry-run: install determinate nix"
  else
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
  fi
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh || true
fi

# 3. link home configs (fallback until home-manager runs; mirrors home-entry.nix:
#    every dir in configs/dotconfig becomes ~/.config/<dir>, except starship/
#    (file -> ~/.config/starship.toml) and mimeapps.list (file, not dir))
link() { # link <src> <dst>: idempotent, backs up real files/dirs to *.pre-dotfiles
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    if [ -e "$dst.pre-dotfiles" ]; then
      echo "refusing to overwrite backup: $dst.pre-dotfiles exists" >&2; exit 1
    fi
    run mv "$dst" "$dst.pre-dotfiles"; warn "backup: $dst -> $dst.pre-dotfiles"
  fi
  run ln -sfn "$src" "$dst"
}
log "linking home configs..."
run mkdir -p "$HOME/.config" "$HOME/.local/share"
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

# 4. system rebuild via flake (nh preferred, nixos-rebuild fallback).
#    Always dry-builds first; aborts before switching on failure.
if [ "$REBUILD" -eq 1 ]; then
  HW="$REPO/hosts/nixos/hardware-configuration.nix"
  if [ ! -s "$HW" ]; then
    if [ -e /etc/nixos/hardware-configuration.nix ]; then
      log "taking hardware-configuration from host..."
      run cp /etc/nixos/hardware-configuration.nix "$HW"
    else
      warn "no hardware-configuration found (repo or /etc/nixos) - aborting, refusing to build a system without filesystems"
      exit 1
    fi
  fi
  # Nix wertet lokale Git-Flakes ohne ignorierte Dateien aus: HW ist git-ignoriert
  # (host-spezifisch), muss aber fuer den Build sichtbar sein.
  run git -C "$REPO" add -f "$HW"
  log "dry-build..."
  if command -v nh >/dev/null 2>&1; then
    log "nh os switch $REPO..."
    run sudo nh os switch "$REPO"
  elif command -v nixos-rebuild >/dev/null 2>&1; then
    log "nixos-rebuild switch --flake $REPO#nixos..."
    run sudo nixos-rebuild switch --flake "$REPO#nixos"
  else
    warn "neither nh nor nixos-rebuild found"
    exit 1
  fi
fi

# 5. external binaries ohne Nix-Quelle (per machine, NICHT deklarativ moeglich).
#    zen-browser kommt aus dem Flake-Input via home.packages (home/programs/default.nix).
if [ "$USER_PKGS" -eq 1 ]; then
  log "external binaries..."
  need_bin() { [ -x "$HOME/.local/bin/$1" ]; }
  need_bin omp && need_bin cliamp-real && need_bin zapfast-real && need_bin pakmc-bin \
    || warn "external binaries missing (~/.local/bin/{omp,cliamp-real,zapfast-real,pakmc-bin})"
fi

exec "$REPO/scripts/verify.sh"
