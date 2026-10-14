#!/usr/bin/env bash
# scripts/lib.sh — shared helpers for apply.sh / apps.sh /
# install-wizard.sh / check.sh. Sourced, never executed. Strict, dependency-free
# (bash + coreutils only).
#
# Categories (documentation required by the architecture audit):
#   declarative  Nix/Home-Manager (nix/home-entry.nix) — takes effect only after rebuild
#   generated    nix/machine/local.nix + hardware-configuration.nix (per machine)
#   deployed     ~/.config symlinks with backup (explicit, no silent following)
#   local-only   ~/Pictures/Wallpapers, Secrets, ~/.local/state (left in place)

# Guard: source only.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "lib.sh is sourced, not executed" >&2
  exit 1
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- catalog eval -----------------------------------------------------------
# DOT_LIB: minimal nix lib shim for bundles.nix metadata queries (appIds,
# blurbs, expandGroups). Pure builtins — no <nixpkgs> lookup, so it works
# even when NIX_PATH is unset (sudo, setsid, minimal envs). Full builds
# still use the real nixpkgs lib via the flake.
DOT_LIB='{ unique = xs: builtins.foldl'"'"' (a: x: if builtins.elem x a then a else a ++ [x]) [] xs; assertMsg = c: m: if c then true else throw m; }'
# DOT_CATALOG: nix expr prelude binding `b` (the catalog) with the shim lib.
# Usage: nix eval --impure --expr "$DOT_CATALOG <body>" (pkgs=null: metadata
# only — package values would need real pkgs/flake inputs).
DOT_CATALOG='let b = import ./nix/home/programs/bundles.nix {pkgs=null; inputs={}; lib='"$DOT_LIB"';}; in'
# --- output ---------------------------------------------------------------
_dot_log() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
_dot_warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
_dot_err() { printf '\033[1;31mXX\033[0m %s\n' "$*" >&2; }
_dot_ok() { printf '\033[1;32mok\033[0m %s\n' "$*"; }

# --- environment ----------------------------------------------------------
# dot_on_nixos: true auf installiertem NixOS, false auf Arch/ISO/live.
dot_on_nixos() { [[ -e /etc/NIXOS ]] || grep -qi '^NAME=.*nixos' /etc/os-release 2>/dev/null; }

# dot_on_live_iso: true on minimal ISO RAM (nixos-rebuild would change live only).
dot_on_live_iso() {
  grep -q ' / iso9660 ' /proc/mounts 2>/dev/null && return 0
  [[ "${HOSTNAME:-}" == nixos-installer* || "${HOSTNAME:-}" == nixos-live* ]] && return 0
  return 1
}

# dot_require_nixos: aborts outside NixOS (protects Arch dev PC).
dot_require_nixos() {
  if ! dot_on_nixos; then
    _dot_err "Run on NixOS only (this is: $(grep -oP '^PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || uname -s))."
    _dot_err "The Arch/Omarchy PC is a development machine, not an install target."
    return 1
  fi
}

# dot_require_not_live: nixos-rebuild/nh switch are forbidden on the live ISO.
dot_require_not_live() {
  if dot_on_live_iso; then
    _dot_err "Live ISO detected: 'nixos-rebuild switch' would only change the RAM system."
    return 1
  fi
}

# dot_require_user_match: whoami must match lysec.username.
dot_require_user_match() {
  local want="${1:?username missing}"
  if [[ "${EUID}" -eq 0 ]]; then
    _dot_err "Do not run as root (HOME would be /root, repo paths wrong)."
    return 1
  fi
  if [[ "$(whoami)" != "$want" ]]; then
    _dot_err "whoami ($(whoami)) != lysec.username ($want). Log in as $want."
    return 1
  fi
}

# --- repo state -----------------------------------------------------------
# dot_rev: short git rev or "nogit" (informational only — builds and
# installer NEVER depend on git state; see dot_snapshot).
dot_rev() { git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo "nogit"; }


# --- deploy: symlinks with backup ------------------------------------------
# dot_link <src> <dst>: idempotent; real files -> *.pre-dotfiles (never
# overwrite); broken symlinks (no content) are replaced with a warning.
dot_link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && ! -e "$dst" ]]; then
    _dot_warn "broken symlink: $dst (-> $(readlink "$dst")) — replacing."
    rm "$dst"
  elif [[ -e "$dst" && ! -L "$dst" ]]; then
    if [[ -e "$dst.pre-dotfiles" || -L "$dst.pre-dotfiles" ]]; then
      _dot_err "Backup already exists: $dst.pre-dotfiles — resolve manually."
      return 1
    fi
    mv "$dst" "$dst.pre-dotfiles"
    _dot_warn "backup: $dst -> $dst.pre-dotfiles"
  fi
  ln -sfn "$src" "$dst"
}

# --- hardware config ------------------------------------------------------
# dot_adopt_hw <dest>: adopts /etc/nixos/hardware-configuration.nix ONLY with
# validation (fileSystems marker + nix parse). Silent-mixing guard kept.
dot_adopt_hw() {
  local dest="${1:?dest missing}" src="/etc/nixos/hardware-configuration.nix"
  [[ -f "$src" ]] || {
    _dot_err "No hardware config under $src (run nixos-generate-config)."
    return 1
  }
  grep -q 'fileSystems' "$src" || {
    _dot_err "$src contains no fileSystems — wrong machine? Aborting."
    return 1
  }
  if command -v nix-instantiate >/dev/null 2>&1; then
    nix-instantiate --parse "$src" >/dev/null || {
      _dot_err "$src does not parse as Nix — aborting."
      return 1
    }
  fi
  if [[ -e "$dest" ]] && ! diff -q "$src" "$dest" >/dev/null 2>&1; then
    _dot_warn "Hardware config differs — keeping existing one, diff:"
    diff -u "$dest" "$src" || true
    _dot_err "Check manually (wrong UUIDs = unbootable), then run again."
    return 1
  fi
  cp "$src" "$dest"
  _dot_log "hardware-configuration adopted (validated)."
}

# dot_snapshot: build a flake-evaluable source tree from the working dir.
# Why: git-backed flakes only see tracked+staged files; untracked modules
# silently vanish from evaluation, and hardware-configuration.nix /
# local.nix are git-ignored by design. Instead of mutating the git index
# (replaces the old git-index staging), copy the working tree to a temp dir and build
# it as a `path:` flake, which evaluates every file present on disk.
# - Includes untracked files, dirty edits, hw config, local.nix.
# - Excludes .git/ and result/ symlinks (never part of evaluation).
# - No index/staging mutation, no commits, no secret leak beyond the local
#   machine (snapshot lives in $TMPDIR, mode 700).
# Usage: snap="$(dot_snapshot)" || exit 1; trap 'rm -rf "$snap"' EXIT
#        nixos-rebuild switch --flake "path:$snap#nixos"
dot_snapshot() {
  local snap hw
  snap="$(mktemp -d "${TMPDIR:-/tmp}/dot-snap.XXXXXX")" || return 1
  chmod 700 "$snap"
  # Excludes: .git (history), result* (build outputs, any level),
  # *.pre-dotfiles (installer backups — live-machine files, not config).
  tar -C "$REPO" -cf - --exclude=.git --exclude='result*' --exclude='*.pre-dotfiles' . 2>/dev/null | tar -C "$snap" -xf - || {
    _dot_err "snapshot copy failed."
    rm -rf "$snap"
    return 1
  }
  hw="$snap/nix/machine/hardware-configuration.nix"
  if [[ ! -s "$hw" ]]; then
    dot_adopt_hw "$hw" >&2 || { rm -rf "$snap"; return 1; }
  fi
  printf '%s' "$snap"
}
