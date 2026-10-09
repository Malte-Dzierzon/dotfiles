#!/usr/bin/env bash
# scripts/lib.sh — shared helpers for install.sh / apply.sh / update.sh /
# live-installer.sh. Sourced, never executed. Strict, dependency-free
# (bash + coreutils only; works on Minimal ISO and NixOS).
#
# Categories (Doku-Pflicht aus dem Architektur-Audit):
#   declarative  Nix/Home-Manager (home-entry.nix) — wirksam erst nach rebuild
#   generated    hosts/nixos/local.nix + hardware-configuration.nix (pro Maschine)
#   deployed     ~/.config-Symlinks mit Backup (explizit, kein stilles Folgen)
#   local-only   ~/Pictures/Wallpapers, Secrets, ~/.local/state (bleibt liegen)

# Guard: nur sourcen.
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

# dot_on_live_iso: true auf Minimal-ISO-RAM (nixos-rebuild wuerde NUR live aendern).
dot_on_live_iso() {
  grep -q ' / iso9660 ' /proc/mounts 2>/dev/null && return 0
  [[ "${HOSTNAME:-}" == nixos-installer* || "${HOSTNAME:-}" == nixos-live* ]] && return 0
  return 1
}

# dot_require_nixos: bricht ab ausserhalb von NixOS (schuetzt Arch-Dev-PC).
dot_require_nixos() {
  if ! dot_on_nixos; then
    _dot_err "Nur auf NixOS ausfuehren (dies ist: $(grep -oP '^PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || uname -s))."
    _dot_err "Der Arch/Omarchy-PC ist Entwicklungsmaschine, kein Installationsziel."
    return 1
  fi
}

# dot_require_not_live: nixos-rebuild/nh switch sind auf Live-ISO verboten.
dot_require_not_live() {
  if dot_on_live_iso; then
    _dot_err "Live-ISO erkannt: 'nixos-rebuild switch' wuerde nur das RAM-System aendern."
    _dot_err "Fuer Neuinstallation: scripts/live-installer.sh (nixos-install --root /mnt)."
    return 1
  fi
}

# dot_require_user_match: whoami muss lysec.username entsprechen.
dot_require_user_match() {
  local want="${1:?username fehlt}"
  if [[ "${EUID}" -eq 0 ]]; then
    _dot_err "Nicht als root ausfuehren (HOME waere /root, Repo-Pfade falsch)."
    return 1
  fi
  if [[ "$(whoami)" != "$want" ]]; then
    _dot_err "whoami ($(whoami)) != lysec.username ($want). Als $want einloggen."
    return 1
  fi
}

# --- repo state -----------------------------------------------------------
# dot_repo_clean: bricht bei uncommitteten Aenderungen ab (ausser HW-Staging,
# das der Installer per trap selbst verwaltet).
dot_repo_clean() {
  local dirty
  dirty="$(git -C "$REPO" status --porcelain --untracked-files=no -- . ':!hosts/nixos/hardware-configuration.nix' 2>/dev/null)" || {
    _dot_err "Kein Git-Repo unter $REPO."
    return 1
  }
  if [[ -n "$dirty" ]]; then
    _dot_err "Uncommittete Aenderungen — erst reviewen/commits/stashen, dann rebuild:"
    printf '%s\n' "$dirty" >&2
    return 1
  fi
}

dot_current_rev() { git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo "unknown"; }

# --- deploy: symlinks mit Backup ------------------------------------------
# dot_link <src> <dst>: idempotent; echte Dateien -> *.pre-dotfiles (nie ueberschreiben).
dot_link() {
  local src="$1" dst="$2"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    if [[ -e "$dst.pre-dotfiles" ]]; then
      _dot_err "Backup existiert schon: $dst.pre-dotfiles — manuell loesen."
      return 1
    fi
    mv "$dst" "$dst.pre-dotfiles"
    _dot_warn "backup: $dst -> $dst.pre-dotfiles"
  fi
  ln -sfn "$src" "$dst"
}

# --- hardware config ------------------------------------------------------
# dot_adopt_hw <dest>: uebernimmt /etc/nixos/hardware-configuration.nix NUR mit
# Validierung (fileSystems-Marker + nix-parse). Kept silent-Mixing-Schutz.
dot_adopt_hw() {
  local dest="${1:?dest fehlt}" src="/etc/nixos/hardware-configuration.nix"
  [[ -f "$src" ]] || {
    _dot_err "Keine Hardware-Config unter $src (nixos-generate-config --root /mnt auf ISO)."
    return 1
  }
  grep -q 'fileSystems' "$src" || {
    _dot_err "$src enthaelt keine fileSystems — falsche Maschine? Abbruch."
    return 1
  }
  if command -v nix-instantiate >/dev/null 2>&1; then
    nix-instantiate --parse "$src" >/dev/null || {
      _dot_err "$src parst nicht als Nix — Abbruch."
      return 1
    }
  fi
  if [[ -e "$dest" ]] && ! diff -q "$src" "$dest" >/dev/null 2>&1; then
    _dot_warn "Hardware-Config weicht ab — vorhandene bleibt, Diff:"
    diff -u "$dest" "$src" || true
    _dot_err "Manuell pruefen (falsche UUIDs = unbootbar), dann erneut laufen."
    return 1
  fi
  cp "$src" "$dest"
  _dot_log "hardware-configuration uebernommen (validiert)."
}

# dot_with_hw_staged <func> [args...]: staged HW + local.nix force-add fuer den Flake-Build,
# danach IMMER reset (+loeschen, falls vorher nicht vorhanden). Verhindert
# UUID-Leaks nach GitHub. local.nix ist git-ignoriert, aber die Flake-Eval sieht nur
# gestagte Dateien — ohne Staging wuerde die Installer-Auswahl (bundles, tablet, ...)
# still auf settings.nix-Defaults fallen. Cleanup laeuft explizit UND per REPORT-Trap, damit
# auch SIGINT/SIGTERM/SSH-Abbruch waehrend des Builds nichts gestagt laesst.
# Regel: kein Early-Return zwischen add und cleanup einbauen!
dot_with_hw_staged() {
  local hw="$REPO/hosts/nixos/hardware-configuration.nix"
  local local="$REPO/hosts/nixos/local.nix"
  local had_hw=0 had_local=0 rc=0
  [[ -f "$hw" ]] && had_hw=1
  [[ -f "$local" ]] && had_local=1
  git -C "$REPO" add -f "$hw" 2>/dev/null || {
    _dot_err "git add -f $hw fehlgeschlagen."
    return 1
  }
  if [[ $had_local -eq 1 ]]; then
    git -C "$REPO" add -f "$local" 2>/dev/null || {
      _dot_err "git add -f $local fehlgeschlagen."
      git -C "$REPO" reset -q HEAD -- "$hw" 2>/dev/null || true
      [[ $had_hw -eq 0 ]] && rm -f "$hw"
      return 1
    }
  fi
  dot_hw_cleanup() {
    git -C "$REPO" reset -q HEAD -- "$hw" "$local" 2>/dev/null || true
    if [[ $had_hw -eq 0 ]]; then rm -f "$hw"; fi
    # local.nix nie loeschen — nur unstagen (ist echte Maschinen-Config, kein Generat).
  }
  trap dot_hw_cleanup RETURN INT TERM EXIT
  "$@" || rc=$?
  trap - RETURN INT TERM EXIT
  dot_hw_cleanup
  unset -f dot_hw_cleanup
  return $rc
}
