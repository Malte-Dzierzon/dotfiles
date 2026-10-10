#!/usr/bin/env bash
# verify.sh — read-only health check. Changes nothing.
# Home-manager links whole dirs (~/.config/<app> -> repo/<app>/, visible as a
# nested <app>/<app> self-symlink); the installer links the dir directly.
# Plain files (starship.toml) are compared by content.
# Exit: 0 = alle fatalen Checks ok; 1 = Fehler. Warnungen (Binaer-/XDG-Checks
# auf Konsolen-Systemen) zaehlen nicht als Fehler, werden aber angezeigt.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0
fail=0
warns=0
VERBOSE=0
[[ "${1:-}" == "--verbose" || "${1:-}" == "-v" ]] && VERBOSE=1
ok() { pass=$((pass + 1)); if [[ $VERBOSE -eq 1 ]]; then printf '\033[1;32mok\033[0m %s\n' "$*"; fi; }
bad() { fail=$((fail + 1)); printf '\033[1;31mFAIL\033[0m %s\n' "$*"; }
soft() { warns=$((warns + 1)); printf '\033[1;33mwarn\033[0m %s\n' "$*"; }

resolves_to_repo() { # <path>: itself or any symlink <=2 deep points into $REPO or the HM store
  local t="$1" l
  [ -L "$t" ] && [[ "$(readlink "$t")" == "$REPO"* ]] && return 0
  [ -L "$t" ] && [[ "$(readlink "$t")" == /nix/store/* ]] && return 0
  while IFS= read -r l; do
    [[ "$(readlink "$l")" == "$REPO"* ]] && return 0
    [[ "$(readlink "$l")" == /nix/store/* ]] && return 0
  done < <(find "$t" -maxdepth 2 -type l 2>/dev/null)
  return 1
}

for d in "$REPO/dotfiles/.config"/*/; do
  n=$(basename "$d")
  if [ "$n" = "starship" ]; then
    t="$HOME/.config/starship.toml"; src="$REPO/dotfiles/.config/starship/starship.toml"
  else
    t="$HOME/.config/$n"; src=""
  fi
  if [ -n "${src:-}" ]; then
    if [ -e "$t" ] && diff -q "$t" "$src" >/dev/null 2>&1; then ok "config $n"; else bad "config $n (missing or differs from repo)"; fi
  elif [ -e "$t" ] && resolves_to_repo "$t"; then ok "config $n"; else bad "config $n (missing or not linked to repo)"; fi
done
# mimeapps.list ist eine Datei (kein Dir) — der Glob oben greift nie: explizit pruefen.
if [ -e "$HOME/.config/mimeapps.list" ] && [ ! -L "$HOME/.config/mimeapps.list" ] && diff -q "$HOME/.config/mimeapps.list" "$REPO/dotfiles/.config/mimeapps.list" >/dev/null 2>&1; then
  ok "config mimeapps.list"
elif resolves_to_repo "$HOME/.config/mimeapps.list" 2>/dev/null; then
  ok "config mimeapps.list"
else
  bad "config mimeapps.list (missing or not linked to repo)"
fi
for t in "$HOME/.local/bin" "$HOME/.local/share/applications"; do
  if [ -e "$t" ] && resolves_to_repo "$t"; then ok "link $t"; else bad "link $t missing or not linked to repo"; fi
done

# 2. key binaries (soft: auf Konsolen-Systemen ohne Session-PATH nur Warnung)
for b in umbriel noctalia zen zeditor foot walker starship fish; do
  if command -v "$b" >/dev/null 2>&1; then ok "bin $b"; else soft "bin $b missing"; fi
done

# 3. defaults (soft: braucht laufende XDG-Session)
if [ "$(xdg-settings get default-web-browser 2>/dev/null)" = "zen.desktop" ]; then ok "default browser zen"; else soft "default browser not zen"; fi
if xdg-mime query default text/plain 2>/dev/null | grep -q "Zed"; then ok "default editor zed"; else soft "default editor not zed"; fi

# 4. noctalia state present (tracked in repo, must exist live)
if [ -f "$HOME/.local/state/noctalia/settings.toml" ]; then ok "noctalia settings"; else bad "noctalia settings missing"; fi

# 5. installer state: local.nix + hardware config present, host files ignored
if [ -f "$REPO/hosts/nixos/local.nix" ]; then ok "local.nix present"; else soft "local.nix missing (installer-Auswahl fehlt — wizard/apply)"; fi
if [ -s "$REPO/hosts/nixos/hardware-configuration.nix" ]; then ok "hardware-configuration present"; else bad "hardware-configuration missing"; fi
if git -C "$REPO" check-ignore -q hosts/nixos/hardware-configuration.nix 2>/dev/null \
  && git -C "$REPO" check-ignore -q hosts/nixos/local.nix 2>/dev/null; then
  ok "host files ignored"
else
  bad "host files NOT ignored (UUID-Leak-Risiko)"
fi

# 6. no secrets tracked (5 patterns wie CI; kein false-green ohne Git)
if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  bad "kein Git-Repo — Secret-Scan unmoeglich"
else
  has_secret=0
  P1='ghp_[A-Za-z0-9]'; P1="${P1}{20,}"
  git -C "$REPO" grep -q -iE "$P1" -- . && has_secret=1
  P2='github'; P2="${P2}_pat_"
  git -C "$REPO" grep -q "$P2" -- . && has_secret=1
  P3='BEGIN (RSA |OPENSSH |PGP )?PRIVATE '; P3="${P3}KEY"
  git -C "$REPO" grep -q -E "$P3" -- . && has_secret=1
  P4='xox'; P4="${P4}[bpas]-"
  git -C "$REPO" grep -q -E "$P4" -- . && has_secret=1
  P5='sk-(live|ant)-'
  git -C "$REPO" grep -q -E "$P5" -- . && has_secret=1
  if [ "$has_secret" -eq 0 ]; then ok "no secrets tracked"; else bad "possible secret in repo"; fi
fi

if [[ $VERBOSE -eq 0 && $fail -eq 0 ]]; then
  echo "ok: $pass checks passed, $warns warnings"
else
  echo "--- $pass ok, $fail failed, $warns warnings ---"
fi
if [ "$fail" -gt 0 ]; then exit 1; else exit 0; fi
