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
# Etwaige local.nix-Username-Ueberschreibung auslesen (CWD-unabhaengig;
# faellt auf settings-Default zurueck, wenn nix fehlt — preflight bleibt strikt).
WANT_USER="$(cd "$REPO" && nix eval --impure --raw --expr '(import ./hosts/nixos/settings.nix).username' --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo xealom)"
if [[ -f "$REPO/hosts/nixos/local.nix" ]]; then
  LOCAL_USER="$(cd "$REPO" && nix eval --impure --raw --expr '(import ./hosts/nixos/local.nix {lib = {mkDefault = x: x;};}).lysec.username or ""' --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo "")"
  [[ -n "$LOCAL_USER" ]] && WANT_USER="$LOCAL_USER"
fi
dot_require_user_match "$WANT_USER"
command -v sudo >/dev/null 2>&1 || {
  echo "XX sudo missing." >&2
  exit 1
}
run sudo -v
dot_repo_clean
if ! ping -c1 -W3 cache.nixos.org >/dev/null 2>&1; then
  _dot_warn "cache.nixos.org unreachable — trying build anyway (may use store)."
fi

# --- 1. deploy ~/.config symlinks (deployed category, mit Backup) -------------
ui_head "link home configs"
run mkdir -p "$HOME/.config" "$HOME/.local/share"
LINKED=0 CHANGED=0
link_one() { # <src> <dst> <name>: linkt, meldet new/changed/kept.
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
# Noctalia Live-Settings seeden (NUR wenn fehlend): Datei bleibt beschreibbar,
# HM verwaltet sie bewusst NICHT (Store-Link waere read-only, Noctalia kann
# nicht zurueckschreiben). Repo = Startpunkt, live = unversioniert.
if [[ ! -e "$HOME/.local/state/noctalia/settings.toml" ]]; then
  run mkdir -p "$HOME/.local/state/noctalia"
  run cp "$REPO/dotfiles/.local/state/noctalia/settings.toml" "$HOME/.local/state/noctalia/settings.toml"
fi

# --- 2. rebuild ---------------------------------------------------------------
if [[ $REBUILD -eq 1 ]]; then
  HW="$REPO/hosts/nixos/hardware-configuration.nix"
  if [[ ! -s "$HW" ]]; then
    _dot_log "keine Hardware-Config im Repo — adoptiere validiert vom Host..."
    run dot_adopt_hw "$HW"
  fi
ui_head "dry build"
  if [[ $DRY_RUN -eq 1 ]]; then
    if command -v nh >/dev/null 2>&1; then
      run dot_with_hw_staged nh os build "$REPO"
    else
      run dot_with_hw_staged nixos-rebuild dry-build --flake "$REPO#nixos"
    fi
  else
    # Erfolg ist still (Fehler brechen via set -e ab); nur der switch zeigt Details.
    if command -v nh >/dev/null 2>&1; then
      run dot_with_hw_staged nh os build "$REPO" >/dev/null 2>&1 || {
        _dot_err "dry build failed — switch aborted."
        run dot_with_hw_staged nh os build "$REPO"
      }
    else
      run dot_with_hw_staged nixos-rebuild dry-build --flake "$REPO#nixos" >/dev/null 2>&1 || {
        _dot_err "dry build failed — switch aborted."
        run dot_with_hw_staged nixos-rebuild dry-build --flake "$REPO#nixos"
      }
    fi
    _dot_ok "dry build ok"
  fi
ui_head "switch"
  if command -v nh >/dev/null 2>&1; then
    # nh als User laufen lassen (eskaliert selbst per sudo); NICHT sudo nh —
    # nh verweigert Root ("Don't run nh os as root").
    if [[ $DRY_RUN -eq 1 ]]; then run dot_with_hw_staged nh os switch "$REPO"; else ui_box dot_with_hw_staged nh os switch "$REPO"; fi
  elif command -v nixos-rebuild >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then run dot_with_hw_staged sudo nixos-rebuild switch --flake "$REPO#nixos"; else ui_box dot_with_hw_staged sudo nixos-rebuild switch --flake "$REPO#nixos"; fi
  else
    _dot_warn "neither nh nor nixos-rebuild found."
    exit 1
  fi
fi

# --- 3. external binaries (warn-only, per machine) ----------------------------
ui_head "external binaries"
WARNED=0
# omp/cliamp kommen aus Nix (Flake/nixpkgs) — nur Erreichbarkeit pruefen.
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

# Verify beschreibt das LIVE-System, nicht die Vorschau — bei --dry-run/--no-rebuild
# (REBUILD=0) irrefuehrend, daher nur nach echtem switch.
if [[ $REBUILD -eq 1 && $DRY_RUN -eq 0 ]]; then
  exec "$REPO/scripts/verify.sh"
else
  echo ":: preview done — verify runs only after a real switch." >&2
fi
