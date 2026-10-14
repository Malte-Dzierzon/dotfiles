#!/usr/bin/env bash
# bootstrap-opencode.sh — install stable OpenCode CLI + merge migration AGENTS.md.
# Scope: OpenCode only. No system packages, no desktop, no drivers, no credentials.
# Official install: curl -fsSL https://opencode.ai/install | bash (no sudo needed).
# Usage: ./migration/bootstrap-opencode.sh [--help] [--dry-run]
set -euo pipefail

SELF="$(readlink -f "$0")"
REPO="$(cd "$(dirname "$SELF")/.." && pwd)"
TEMPLATE="$REPO/configs/ai/opencode/AGENTS.md"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/AGENTS.md"
INSTALL_URL="https://opencode.ai/install"
BEGIN="<!-- dotfiles:opencode-migration:begin -->"
END="<!-- dotfiles:opencode-migration:end -->"

usage() { sed -n '2,6p' "$SELF"; echo; echo "Options: --help, --dry-run"; }
DRY=0
for a in "$@"; do case "$a" in --help) usage; exit 0;; --dry-run) DRY=1;; *) echo "unknown arg: $a" >&2; usage; exit 2;; esac; done
run() { if (( DRY )); then echo "[dry-run] $*"; else "$@"; fi; }

# tools + arch
command -v bash >/dev/null || { echo "need bash" >&2; exit 1; }
command -v curl >/dev/null || { echo "need curl (zypper in curl)" >&2; exit 1; }
case "$(uname -m)" in x86_64|aarch64) ;; *) echo "unsupported arch: $(uname -m)" >&2; exit 1;; esac
[[ -f "$TEMPLATE" ]] || { echo "template missing: $TEMPLATE" >&2; exit 1; }

# install (idempotent: skip when present unless --dry-run shows it)
if command -v opencode >/dev/null; then
  echo "opencode already installed: $(command -v opencode)"
else
  echo "installing opencode (stable, user scope)…"
  if (( DRY )); then echo "[dry-run] curl -fsSL $INSTALL_URL | bash"; else curl -fsSL "$INSTALL_URL" | bash; fi
fi

# merge template into TARGET without destroying personal notes
if (( DRY )); then
  echo "[dry-run] merge $TEMPLATE -> $TARGET (backup *.bak, marked section)"
else
  mkdir -p "$(dirname "$TARGET")"
  [[ -f "$TARGET" ]] && cp -f "$TARGET" "$TARGET.bak"
  if [[ -f "$TARGET" ]] && grep -qF "$BEGIN" "$TARGET"; then
    # replace marked section with awk (no python needed); personal notes outside markers untouched
    tmp="$(mktemp)"
    awk -v b="$BEGIN" -v e="$END" -v src="$TEMPLATE" 'BEGIN{inblk=0} $0==b{print; while((getline line < src) > 0) print line; inblk=1; next} $0==e{inblk=0} !inblk{print}' "$TARGET" > "$tmp" && mv "$tmp" "$TARGET"
    echo "updated marked section in $TARGET (backup $TARGET.bak)"
  elif [[ -f "$TARGET" ]]; then
    { echo; echo "$BEGIN"; cat "$TEMPLATE"; echo "$END"; } >> "$TARGET"
    echo "appended marked section to $TARGET (backup $TARGET.bak)"
  else
    { echo "$BEGIN"; cat "$TEMPLATE"; echo "$END"; } > "$TARGET"
    echo "created $TARGET"
  fi
fi

# verify (PATH hint only, never modifies shell rc)
if command -v opencode >/dev/null; then
  echo "OK: $(command -v opencode)"
else
  echo "NOTE: opencode installed but not in PATH — add ~/.opencode/bin or ~/.local/bin to PATH, then re-login."
fi
echo "No provider/model configured (intentional — connect separately with /connect)."
