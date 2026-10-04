#!/usr/bin/env bash
# verify.sh — read-only health check. Changes nothing.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0
fail=0
ok() { pass=$((pass + 1)); printf '\033[1;32mok\033[0m %s\n' "$*"; }
bad() { fail=$((fail + 1)); printf '\033[1;31mFAIL\033[0m %s\n' "$*"; }

# 1. symlinks resolve
for d in "$REPO/configs/dotconfig"/*/; do
  n=$(basename "$d")
  [ "$n" = "mimeapps.list" ] && t="$HOME/.config/mimeapps.list" || { [ "$n" = "starship" ] && t="$HOME/.config/starship.toml" || t="$HOME/.config/$n"; }
  [ -e "$t" ] && ok "link $t" || bad "missing $t"
done

# 2. key binaries
for b in niri noctalia zen zeditor foot walker starship fish; do
  command -v "$b" >/dev/null 2>&1 && ok "bin $b" || bad "bin $b missing"
done

# 3. defaults
[ "$(xdg-settings get default-web-browser 2>/dev/null)" = "zen.desktop" ] && ok "default browser zen" || bad "default browser not zen"
xdg-mime query default text/plain 2>/dev/null | grep -q "Zed" && ok "default editor zed" || bad "default editor not zed"

# 4. noctalia state present (not in repo, must exist live)
[ -f "$HOME/.local/state/noctalia/settings.toml" ] && ok "noctalia settings" || bad "noctalia settings missing"

# 5. no secrets tracked
cd "$REPO" && ! git grep -q -iE "ghp_[A-Za-z0-9]{20,}|github_pat_|-----BEGIN (RSA |OPENSSH )?PRIVATE KEY" -- . && ok "no secrets tracked" || bad "possible secret in repo"

echo "--- $pass ok, $fail failed ---"
exit "$fail"
