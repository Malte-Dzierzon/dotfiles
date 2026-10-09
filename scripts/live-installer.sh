#!/usr/bin/env bash
# live-installer.sh — Fresh installation from the NixOS Minimal ISO.
#
# Bootstraps a TUI (gum > dialog > pure-bash fallback), collects keyboard /
# profile / identity / bundles, partitions NOTHING automatically, and drives
# `nixos-install --root /mnt` into a manually prepared /mnt.
#
# Start (documented one-liner, ref-pinned for reproducibility):
#   REF=<commit-sha>; bash <(curl --proto '=https' --tlsv1.2 -fsSL \
#     https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/$REF/scripts/live-installer.sh)
#
# The bootstrap below (~40 lines incl. comments) is the ONLY code executed
# from the network before review; everything privileged happens after the
# final confirmation screen, inside the fetched checkout.
set -euo pipefail

REPO_URL="https://github.com/Malte-Dzierzon/dotfiles.git"
DEST="${DEST:-/tmp/dotfiles}"
REF="${REF:-main}"

log() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mXX\033[0m %s\n' "$*" >&2; exit 1; }

# --- 0. live environment ---------------------------------------------------
if [[ "${EUID}" -eq 0 ]]; then
  die "Als normaler Live-User starten (nixos-installer), nicht als root — sudo wird gezielt gefragt."
fi
if ! ping -c1 -W3 nixos.org >/dev/null 2>&1; then
  die "Kein Netz (ping nixos.org fehlgeschlagen). Erst: sudo systemctl start NetworkManager && nmtui."
fi
# Minimal-ISO hat kein git: transient via nix-shell bereitstellen.
# nix-shell-Env vererbt sich NICHT — darum laeuft jeder git-Aufruf ueber
# rungit (echtes git, oder nix-shell -p git --run "git ...").
HAVE_SYS_GIT=0
command -v git >/dev/null 2>&1 && HAVE_SYS_GIT=1
if [[ $HAVE_SYS_GIT -eq 0 ]]; then
  command -v nix-shell >/dev/null 2>&1 || die "Weder git noch nix-shell verfuegbar."
  log "git fehlt — nutze transient nix-shell -p git (kein Systemeingriff)..."
fi
# shellcheck disable=SC2086
rungit() {
  if [[ $HAVE_SYS_GIT -eq 1 ]]; then git "$@"; else nix-shell -p git --run "git $*"; fi
}
rungit --version >/dev/null 2>&1 || die "git-Bereitstellung fehlgeschlagen."

# --- 1. fetch checkout (pinned ref, dirty-tree safe) ------------------------
if [[ -d "$DEST/.git" ]]; then
  die "$DEST existiert schon mit Git-Repo — rm -rf $DEST oder DEST=<pfad> setzen (niemals blind ueberschreiben)."
fi
log "clone $REPO_URL @ $REF -> $DEST"
rungit clone --quiet "$REPO_URL" "$DEST" || die "clone fehlgeschlagen."
if [[ "$REF" != "main" ]]; then
  rungit -C "$DEST" checkout --quiet "$REF" || die "ref $REF unbekannt."
fi
log "revision: $(rungit -C "$DEST" rev-parse --short HEAD) ($(rungit -C "$DEST" log -1 --format=%s))"

# Hand over: the full installer runs from the reviewed checkout, not from
# the pipe. `--live` enables the Minimal-ISO path (TUI + /mnt install).
exec bash "$DEST/scripts/install-wizard.sh" --live
