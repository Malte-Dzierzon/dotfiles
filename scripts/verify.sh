#!/usr/bin/env bash
# verify.sh — read-only health check. Changes nothing.
# Home-manager links whole dirs (~/.config/<app> -> repo/<app>/, visible as a
# nested <app>/<app> self-symlink); the installer links the dir directly.
# Plain files (starship.toml) are compared by content.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0
fail=0
ok() { pass=$((pass + 1)); printf '\033[1;32mok\033[0m %s\n' "$*"; }
bad() { fail=$((fail + 1)); printf '\033[1;31mFAIL\033[0m %s\n' "$*"; }

resolves_to_repo() { # <path>: itself or any symlink <=2 deep points into $REPO
  local t="$1" l
  [ -L "$t" ] && [[ "$(readlink "$t")" == "$REPO"* ]] && return 0
  while IFS= read -r l; do
    [[ "$(readlink "$l")" == "$REPO"* ]] && return 0
  done < <(find "$t" -maxdepth 2 -type l 2>/dev/null)
  return 1
}

# 1. configs live in ~/.config and match the repo
for d in "$REPO/configs/dotconfig"/*/; do
  n=$(basename "$d")
  if [ "$n" = "mimeapps.list" ]; then
    t="$HOME/.config/mimeapps.list"; src="$REPO/configs/dotconfig/mimeapps.list"
  elif [ "$n" = "starship" ]; then
    t="$HOME/.config/starship.toml"; src="$REPO/configs/dotconfig/starship/starship.toml"
  else
    t="$HOME/.config/$n"; src=""
  fi
  if [ -n "${src:-}" ]; then
    if [ -e "$t" ] && diff -q "$t" "$src" >/dev/null 2>&1; then ok "config $n"; else bad "config $n (missing or differs from repo)"; fi
  elif [ -e "$t" ] && resolves_to_repo "$t"; then ok "config $n"; else bad "config $n (missing or not linked to repo)"; fi
done
for t in "$HOME/.local/bin" "$HOME/.local/share/applications"; do
  if [ -e "$t" ] && resolves_to_repo "$t"; then ok "link $t"; else bad "link $t missing or not linked to repo"; fi
done

# 2. key binaries
for b in niri noctalia zen zeditor foot walker starship fish; do
  if command -v "$b" >/dev/null 2>&1; then ok "bin $b"; else bad "bin $b missing"; fi
done

# 3. defaults
if [ "$(xdg-settings get default-web-browser 2>/dev/null)" = "zen.desktop" ]; then ok "default browser zen"; else bad "default browser not zen"; fi
if xdg-mime query default text/plain 2>/dev/null | grep -q "Zed"; then ok "default editor zed"; else bad "default editor not zed"; fi

# 4. noctalia state present (tracked in repo, must exist live)
if [ -f "$HOME/.local/state/noctalia/settings.toml" ]; then ok "noctalia settings"; else bad "noctalia settings missing"; fi

# 5. no secrets tracked (split patterns so this file never self-matches)
has_secret=0
P1='ghp_[A-Za-z0-9]'; P1="${P1}{20,}"
git -C "$REPO" grep -q -iE "$P1" -- . && has_secret=1
P2='github'; P2="${P2}_pat_"
git -C "$REPO" grep -q "$P2" -- . && has_secret=1
P3='BEGIN (RSA |OPENSSH |PGP )?PRIVATE '; P3="${P3}KEY"
git -C "$REPO" grep -q -E "$P3" -- . && has_secret=1
if [ "$has_secret" -eq 0 ]; then ok "no secrets tracked"; else bad "possible secret in repo"; fi

echo "--- $pass ok, $fail failed ---"
if [ "$fail" -gt 0 ]; then exit 1; else exit 0; fi
