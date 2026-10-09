#!/usr/bin/env bash
# bootstrap.sh — existing-system checkout helper (KEIN Live-ISO-Weg).
# Erwartet installiertes NixOS; bricht auf Live-ISO/Arch/dirty-tree ab.
#   REF=<sha> DEST=~/Projects/dotfiles bash <(curl --proto '=https' --tlsv1.2 -fsSL \
#     https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/<ref>/scripts/bootstrap.sh)
# Live-ISO-Neuinstallation: scripts/live-installer.sh (nixos-install --root /mnt).
set -euo pipefail
REPO_URL="https://github.com/Malte-Dzierzon/dotfiles.git"
DEST="${DEST:-$HOME/Projects/dotfiles}"
REF="${REF:-main}"
if grep -q ' / iso9660 ' /proc/mounts 2>/dev/null; then
  echo "XX Live-ISO erkannt — bootstrap.sh ist falsch hier. Nutze scripts/live-installer.sh (Anleitung: README)." >&2
  exit 1
fi
if [[ "${EUID}" -eq 0 ]]; then
  echo "XX Nicht als root ausfuehren." >&2
  exit 1
fi
command -v git >/dev/null 2>&1 || { echo "XX git fehlt (z.B. nix-shell -p git) - aborting" >&2; exit 1; }
if [ -d "$DEST/.git" ]; then
  if [ "$REF" = "main" ]; then
    if ! git -C "$DEST" pull --ff-only origin main 2>/dev/null; then
      echo "XX pull fehlgeschlagen (dirty/divergiert?) — erst 'git -C $DEST status' loesen, dann erneut." >&2
      echo "   Der Installer baut NIE aus einem divergierten Baum (kein stilles Weiterlaufen)." >&2
      exit 1
    fi
  else
    # Gepinnter REF (Commit-SHA): kein pull moeglich — fetch + checkout wie im Clone-Pfad.
    git -C "$DEST" fetch origin || { echo "XX fetch fehlgeschlagen." >&2; exit 1; }
    git -C "$DEST" checkout --quiet "$REF" || { echo "XX ref $REF unbekannt." >&2; exit 1; }
  fi
else
  git clone "$REPO_URL" "$DEST"
  if [ "$REF" != "main" ]; then git -C "$DEST" checkout --quiet "$REF"; fi
fi
echo "revision: $(git -C "$DEST" rev-parse --short HEAD)"
exec "$DEST/scripts/apply.sh" "$@"
