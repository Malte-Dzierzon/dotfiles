#!/usr/bin/env bash
# scripts/lib.sh — shared helpers for apply.sh / apps.sh / sync.sh /
# install-wizard.sh. Sourced, never executed. Strict, dependency-free
# (bash + coreutils only).
#
# Categories (documentation required by the architecture audit):
#   declarative  Nix/Home-Manager (home-entry.nix) — takes effect only after rebuild
#   generated    hosts/nixos/local.nix + hardware-configuration.nix (per machine)
#   deployed     ~/.config symlinks with backup (explicit, no silent following)
#   local-only   ~/Pictures/Wallpapers, Secrets, ~/.local/state (left in place)

# Guard: source only.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "lib.sh is sourced, not executed" >&2
  exit 1
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
# dot_repo_clean: aborts on uncommitted changes (except HW staging,
# managed by the installer itself via trap).
dot_repo_clean() {
  local dirty
  dirty="$(git -C "$REPO" status --porcelain --untracked-files=no -- . ':!hosts/nixos/hardware-configuration.nix' 2>/dev/null)" || {
    _dot_err "No git repo under $REPO."
    return 1
  }
  if [[ -n "$dirty" ]]; then
    _dot_err "Uncommitted changes — review/commit/stash first, then rebuild:"
    printf '%s\n' "$dirty" >&2
    return 1
  fi
}

dot_current_rev() { git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo "unknown"; }

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

# dot_with_hw_staged <func> [args...]: builds see the working tree as-is.
# Stages HW + local.nix (force-add, git-ignored) AND all tracked modifications,
# then ALWAYS resets the index. Nix flakes only see staged files — without this
# the switch would silently ignore uncommitted edits. No commit, no push;
# GitHub stays clean. Untracked files stay invisible to the flake (by design).
# Rule: never add an early return between add and cleanup!
dot_with_hw_staged() {
  local hw="$REPO/hosts/nixos/hardware-configuration.nix"
  local local="$REPO/hosts/nixos/local.nix"
  local had_hw=0 had_local=0 rc=0
  [[ -f "$hw" ]] && had_hw=1
  [[ -f "$local" ]] && had_local=1
  if [[ $had_hw -eq 0 ]]; then
    # Adopt instead of aborting: file missing (e.g. after staging cleanup
    # of an earlier build) — adopt validated copy from host.
    dot_adopt_hw "$hw" || return 1
    had_hw=1 # adopted = keep, not delete (next build needs it).
  fi
  git -C "$REPO" add -f "$hw" 2>/dev/null || {
    _dot_err "git add -f $hw failed."
    return 1
  }
  if [[ $had_local -eq 1 ]]; then
    git -C "$REPO" add -f "$local" 2>/dev/null || {
      _dot_err "git add -f $local failed."
      git -C "$REPO" reset -q HEAD -- "$hw" 2>/dev/null || true
      return 1
    }
  fi
  # Stage the working tree (tracked edits + new files, gitignore respected)
  # so the flake build sees exactly what is on disk. Reset afterwards.
  git -C "$REPO" add . 2>/dev/null || true
  dot_hw_cleanup() {
    git -C "$REPO" reset -q HEAD -- . 2>/dev/null || true
    # Never delete the HW file — adopted or manual, it belongs to the host.
    # Only the staging is reset (no UUID leak).
  }
  trap dot_hw_cleanup RETURN INT TERM EXIT
  "$@" || rc=$?
  trap - RETURN INT TERM EXIT
  dot_hw_cleanup
  unset -f dot_hw_cleanup
  return $rc
}
