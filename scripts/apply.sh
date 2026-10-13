#!/usr/bin/env bash
# apply.sh — Mode 2: deliberate configuration apply on installed NixOS.
#
#   ./scripts/apply.sh [--dry-run] [--no-rebuild] [--wizard]
#
# Lifecycle: local checkout is the source. Remote `main` never touches the
# live system; only this command builds + switches. Refuses dirty trees,
# validates hardware config, dry-builds before switching, and resets the
# force-staged hardware file via trap (never leaks UUIDs to GitHub).
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
# shellcheck source=ui.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ui.sh"

DRY_RUN=0 REBUILD=1 WIZARD=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN=1 ;;
    --no-rebuild) REBUILD=0 ;;
    --wizard) WIZARD=1 ;;
    -h | --help) sed -n '2,8p' "$0"; exit 0 ;;
    *)
      echo "unknown: $a" >&2
      exit 1
      ;;
  esac
done

run() {
  if [[ $DRY_RUN -eq 1 ]]; then echo "dry-run: $*"; else "$@"; fi
}

if [[ $WIZARD -eq 1 ]]; then
  exec "$REPO/scripts/install-wizard.sh" --apply
fi

# --- 0. preflight (fatal, before any mutation) --------------------------------
dot_require_nixos
dot_require_not_live
# Read any local.nix username override (CWD-independent;
# falls back to the settings default when nix is missing — preflight stays strict).
WANT_USER="$(cd "$REPO" && nix eval --impure --raw --expr '(import ./hosts/nixos/settings.nix).username' --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo xealom)"
if [[ -f "$REPO/hosts/nixos/local.nix" ]]; then
  LOCAL_USER="$(cd "$REPO" && nix eval --impure --raw --expr '(import ./hosts/nixos/local.nix {lib = {mkDefault = x: x;};}).lysec.username or ""' --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo "")"
  [[ -n "$LOCAL_USER" ]] && WANT_USER="$LOCAL_USER"
fi
dot_require_user_match "$WANT_USER"
for dep in nix sudo; do
  command -v "$dep" >/dev/null 2>&1 || { _dot_err "$dep missing — install it first, then retry."; exit 1; }
done
if ! command -v nh >/dev/null 2>&1 && ! command -v nixos-rebuild >/dev/null 2>&1; then
  _dot_err "neither nh nor nixos-rebuild found — switch impossible."
  exit 1
fi
run sudo -v
if ! ping -c1 -W3 cache.nixos.org >/dev/null 2>&1; then
  _dot_warn "cache.nixos.org unreachable — trying build anyway (may use store)."
fi

# --- 1. deploy ~/.config symlinks (deployed category, with backup) -------------
ui_head "link home configs"
run mkdir -p "$HOME/.config" "$HOME/.local/share"
LINKED=0 CHANGED=0
link_one() { # <src> <dst> <name>: links, reports new/changed/kept.
  local src="$1" dst="$2" name="$3" before="" state="kept"
  [[ -L "$dst" ]] && before="$(readlink "$dst")"
  [[ -e "$dst" && ! -L "$dst" ]] && state="new"
  run dot_link "$src" "$dst"
  if [[ "$state" == "new" ]]; then
    ui_link "$name" new; CHANGED=$((CHANGED + 1))
  elif [[ "$before" != "$src" ]]; then
    if [[ -z "$before" ]]; then ui_link "$name" new; else ui_link "$name" changed; fi
    CHANGED=$((CHANGED + 1))
  else
    [[ $VERBOSE_LINKS -eq 1 ]] && ui_link "$name" kept
  fi
  LINKED=$((LINKED + 1))
}
VERBOSE_LINKS=0; [[ "${DOT_VERBOSE:-}" == "1" ]] && VERBOSE_LINKS=1
for d in "$REPO/dotfiles/.config"/*/; do
  [[ -d "$d" ]] || continue
  n=$(basename "$d")
  case "$n" in
    starship) link_one "$d/starship.toml" "$HOME/.config/starship.toml" "starship.toml" ;;
    mimeapps.list) : ;;
    *) link_one "$d" "$HOME/.config/$n" "$n" ;;
  esac
done
[[ -f "$REPO/dotfiles/.config/mimeapps.list" ]] && link_one "$REPO/dotfiles/.config/mimeapps.list" "$HOME/.config/mimeapps.list" "mimeapps.list"
link_one "$REPO/dotfiles/.local/bin" "$HOME/.local/bin" ".local/bin"
link_one "$REPO/dotfiles/.local/share/applications" "$HOME/.local/share/applications" ".local/applications"
if [[ $CHANGED -eq 0 ]]; then ui_detail "$LINKED links up to date"; else ui_detail "$CHANGED changed · $LINKED total"; fi
# Seed Noctalia live settings (ONLY when missing): file stays writable,
# HM deliberately does NOT manage it (a store link would be read-only, Noctalia could
# not write back). Repo = starting point, live = unversioned.
if [[ ! -e "$HOME/.local/state/noctalia/settings.toml" ]]; then
  run mkdir -p "$HOME/.local/state/noctalia"
  run cp "$REPO/dotfiles/.local/state/noctalia/settings.toml" "$HOME/.local/state/noctalia/settings.toml"
fi

# --- 2. rebuild (snapshot: working tree incl. untracked/hw, no git needed) -----
if [[ $REBUILD -eq 1 ]]; then
  SNAP="$(dot_snapshot)" || exit 1
  trap 'rm -rf "$SNAP"' EXIT INT TERM
  cd "$SNAP" # nh creates ./result in CWD — keep it inside the snapshot.
  ui_detail "source snapshot: working tree (rev $(dot_rev))"
  rebuild() { # <mode: build|switch>: nh preferred, nixos-rebuild fallback.
    # Same source for build AND switch: identical path:$SNAP#nixos ref,
    # snapshot is immutable between the two calls (plain directory copy).
    if command -v nh >/dev/null 2>&1; then
      nh os "$1" "path:$SNAP#nixos"
    else
      sudo nixos-rebuild "$1" --flake "path:$SNAP#nixos"
    fi
  }
ui_head "build"
  if [[ $DRY_RUN -eq 1 ]]; then
    run rebuild build
  else
    # Silent success (errors abort via set -e); the switch shows details.
    run rebuild build >/dev/null 2>&1 || {
      _dot_err "build failed — switch aborted."
      run rebuild build
    }
    _dot_ok "build ok"
  fi
  if [[ $DRY_RUN -eq 0 ]]; then
ui_head "switch (confirm)"
    printf 'Activate this generation now? [y/N]: '
    IFS= read -r _ans || _ans="n"
    [[ "$_ans" == [yYjJ]* ]] || { echo "saved, not activated. Re-run to switch."; exit 0; }
    # nh escalates itself; NOT sudo nh (nh refuses root).
    if command -v nh >/dev/null 2>&1; then ui_box rebuild switch; else ui_box rebuild switch; fi
  else
    run rebuild switch
  fi
  rm -rf "$SNAP"
  trap - EXIT INT TERM
fi

# --- 3. external binaries (warn-only, per machine) ----------------------------
ui_head "external binaries"
WARNED=0
# omp/cliamp come from Nix (flake/nixpkgs) — only check reachability.
for b in omp cliamp; do
  command -v "$b" >/dev/null 2>&1 || { _dot_warn "missing: $b (nix package?)"; WARNED=$((WARNED + 1)); }
done
for b in zapfast-real pakmc-bin; do
  [[ -x "$HOME/.local/bin/$b" ]] || { _dot_warn "missing: ~/.local/bin/$b"; WARNED=$((WARNED + 1)); }
done
for f in "$HOME/.local/share/filius/filius.jar" "$HOME/.local/share/zapfast/libs.conf"; do
  [[ -e "$f" ]] || { _dot_warn "missing: $f"; WARNED=$((WARNED + 1)); }
done
ui_detail "$LINKED links · $WARNED missing"
ui_summary "$LINKED" 0 "$WARNED"

# Verify describes the LIVE system, not the preview — misleading with --dry-run/--no-rebuild
# (REBUILD=0), so only run it after a real switch.
if [[ $REBUILD -eq 1 && $DRY_RUN -eq 0 ]]; then
  exec "$REPO/scripts/verify.sh"
else
  echo ":: preview done — verify runs only after a real switch." >&2
fi
