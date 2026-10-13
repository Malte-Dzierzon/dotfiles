#!/usr/bin/env bash
# check — validate the user-facing config without changing anything.
# Runs: umbriel config validate (via a scratch HOME overlay),
# default-app --list, and mime drift report. Exit 1 on any failure.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

echo "== desktop (umbriel) =="
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/.config/umbriel"
cp "$REPO/dotfiles/.config/umbriel/"*.toml "$tmp/.config/umbriel/"
cp -r "$REPO/dotfiles/.config/umbriel/shaders" "$tmp/.config/umbriel/"
if HOME="$tmp" XDG_CONFIG_HOME="$tmp/.config" umbriel config validate 2>&1 | tail -1; then :; else fail=1; fi
trap - EXIT; rm -rf "$tmp"

echo "== app roles =="
"$REPO/dotfiles/.local/bin/default-app" --list || fail=1

echo "== mime sync =="
"$REPO/scripts/mime.sh" || fail=1

[[ $fail -eq 0 ]] && echo "check: all ok" || { echo "check: FAILED"; exit 1; }
