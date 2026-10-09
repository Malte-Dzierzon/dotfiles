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
  echo "XX sudo fehlt." >&2
  exit 1
}
run sudo -v
dot_repo_clean
if ! ping -c1 -W3 cache.nixos.org >/dev/null 2>&1; then
  _dot_warn "cache.nixos.org nicht erreichbar — Build versucht es trotzdem (ggf. aus dem Store)."
fi

# --- 1. deploy ~/.config symlinks (deployed category, mit Backup) -------------
_dot_log "linking home configs (Backup: *.pre-dotfiles, nie ueberschreiben)..."
run mkdir -p "$HOME/.config" "$HOME/.local/share"
for d in "$REPO/configs/dotconfig"/*/; do
  [[ -d "$d" ]] || continue
  n=$(basename "$d")
  case "$n" in
    starship) run dot_link "$d/starship.toml" "$HOME/.config/starship.toml" ;;
    mimeapps.list) : ;;
    *) run dot_link "$d" "$HOME/.config/$n" ;;
  esac
done
[[ -f "$REPO/configs/dotconfig/mimeapps.list" ]] && run dot_link "$REPO/configs/dotconfig/mimeapps.list" "$HOME/.config/mimeapps.list"
run dot_link "$REPO/home/.local/bin" "$HOME/.local/bin"
run dot_link "$REPO/home/.local/share/applications" "$HOME/.local/share/applications"
# Noctalia Live-Settings seeden (NUR wenn fehlend): Datei bleibt beschreibbar,
# HM verwaltet sie bewusst NICHT (Store-Link waere read-only, Noctalia kann
# nicht zurueckschreiben). Repo = Startpunkt, live = unversioniert.
if [[ ! -e "$HOME/.local/state/noctalia/settings.toml" ]]; then
  run mkdir -p "$HOME/.local/state/noctalia"
  run cp "$REPO/home/.local/state/noctalia/settings.toml" "$HOME/.local/state/noctalia/settings.toml"
fi

# --- 2. rebuild ---------------------------------------------------------------
if [[ $REBUILD -eq 1 ]]; then
  HW="$REPO/hosts/nixos/hardware-configuration.nix"
  if [[ ! -s "$HW" ]]; then
    _dot_log "keine Hardware-Config im Repo — adoptiere validiert vom Host..."
    run dot_adopt_hw "$HW"
  fi
  _dot_log "dry-build (bricht VOR switch bei Fehlern ab)..."
  if command -v nh >/dev/null 2>&1; then
    run dot_with_hw_staged nh os build "$REPO"
  else
    run dot_with_hw_staged nixos-rebuild dry-build --flake "$REPO#nixos"
  fi
  _dot_log "switch..."
  if command -v nh >/dev/null 2>&1; then
    # nh als User laufen lassen (eskaliert selbst per sudo); NICHT sudo nh —
    # nh verweigert Root ("Don't run nh os as root").
    run dot_with_hw_staged nh os switch "$REPO"
  elif command -v nixos-rebuild >/dev/null 2>&1; then
    run dot_with_hw_staged sudo nixos-rebuild switch --flake "$REPO#nixos"
  else
    _dot_warn "weder nh noch nixos-rebuild gefunden."
    exit 1
  fi
fi

# --- 3. external binaries (warn-only, per machine) ----------------------------
_dot_log "external binaries (keine Nix-Quelle, je Rechner)..."
for b in omp cliamp-real zapfast-real pakmc-bin; do
  if [[ -x "$HOME/.local/bin/$b" ]]; then _dot_ok "bin $b"; else _dot_warn "fehlt: ~/.local/bin/$b"; fi
done

# Verify beschreibt das LIVE-System, nicht die Vorschau — bei --dry-run/--no-rebuild
# (REBUILD=0) irrefuehrend, daher nur nach echtem switch.
if [[ $REBUILD -eq 1 && $DRY_RUN -eq 0 ]]; then
  exec "$REPO/scripts/verify.sh"
else
  echo ":: Vorschau beendet — verify.sh laeuft nur nach echtem switch (live-System pruefen)." >&2
fi
