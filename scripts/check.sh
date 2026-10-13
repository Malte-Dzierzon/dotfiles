#!/usr/bin/env bash
# check — read-only validation. Never mutates. Two tiers:
# fast (default): nix parse, required files, bundle names, defaults.toml
# roles, mime drift, symlink sanity, umbriel/noctalia config presence.
# full (--full): + flake evaluation + dry build via snapshot (expensive).
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
source "$REPO/scripts/lib.sh"
FULL=0; [[ "${1:-}" == "--full" ]] && FULL=1
fail=0
ok() { echo "  ok: $*"; }
bad() { echo "  FAIL: $*" >&2; fail=1; }

echo "== nix syntax =="
for f in flake.nix home-entry.nix hosts/nixos/settings.nix hosts/nixos/default.nix \
  home/default.nix home/programs/bundles.nix home/programs/default.nix home/shell/default.nix \
  modules/lysec/options.nix desktops/umbriel/home.nix desktops/umbriel/nixos.nix; do
  if nix-instantiate --parse "$REPO/$f" >/dev/null 2>&1; then ok "$f"; else bad "parse: $f"; fi
done
for m in "$REPO"/modules/nixos/*.nix; do
  nix-instantiate --parse "$m" >/dev/null 2>&1 && ok "$(basename "$m")" || bad "parse: $m"
done

echo "== required files =="
[[ -f "$REPO/flake.lock" ]] && ok "flake.lock" || bad "flake.lock missing"
[[ -f "$REPO/hosts/nixos/hardware-configuration.nix" || -f /etc/nixos/hardware-configuration.nix ]] \
  && ok "hardware config (repo or /etc/nixos)" || bad "no hardware config anywhere"
[[ -f "$REPO/config/defaults.toml" ]] && ok "config/defaults.toml" || bad "defaults.toml missing"

echo "== bundles =="
if command -v nix >/dev/null 2>&1; then
  names="$(cd "$REPO" && nix eval --impure --json --expr '(import ./home/programs/bundles.nix {pkgs=null; inputs={}; lib={};}).names' --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo FAIL)"
  [[ "$names" != "FAIL" ]] && ok "catalog readable" || bad "bundles.nix unreadable"
  for src in "$REPO/hosts/nixos/settings.nix" "$REPO/hosts/nixos/local.nix"; do
    [[ -f "$src" ]] || continue
    sel="$(cd "$REPO" && nix eval --impure --raw --expr "let v = import $src $(basename "$src" .nix | sed 's/.*/{lib={mkDefault=x:x;};}/'); in 1" --extra-experimental-features 'nix-command flakes' 2>/dev/null || true)"
    _=0
  done
  # validate selected bundle names against catalog
  sel="$(cd "$REPO" && nix eval --impure --raw --expr 'builtins.concatStringsSep "," ((import ./hosts/nixos/settings.nix).bundles or [])' --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo "")"
  if [[ -f "$REPO/hosts/nixos/local.nix" ]]; then
    lsel="$(cd "$REPO" && nix eval --impure --raw --expr 'let l = import ./hosts/nixos/local.nix {lib={mkDefault=x:x;};}; in builtins.concatStringsSep "," (l.lysec.bundles or [])' --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo "")"
    [[ -n "$lsel" ]] && sel="$lsel"
  fi
  IFS=',' read -ra _bs <<<"$sel"
  for b in "${_bs[@]}"; do
    [[ "$names" == *"\"$b\""* ]] && ok "bundle: $b" || bad "unknown bundle: $b"
  done
else
  bad "nix not found — evaluation checks skipped"
fi

echo "== app roles + mime =="
"$REPO/dotfiles/.local/bin/default-app" --list >/dev/null 2>&1 && ok "default-app roles" || bad "default-app --list"
"$REPO/scripts/mime.sh" >/dev/null 2>&1 && ok "mime in sync" || bad "mime drift (run: dot mime --fix)"

echo "== symlinks =="
for d in "$REPO"/dotfiles/.config/*/; do
  [[ -d "$d" ]] || continue
  n="$(basename "$d")"
  if [[ -e "$HOME/.config/$n" && ! -L "$HOME/.config/$n" ]]; then bad "~/.config/$n is a real dir (would be backed up on apply)"; fi
done
ok "symlink targets checked"

echo "== desktop configs =="
[[ -f "$REPO/dotfiles/.config/umbriel/config.toml" ]] && ok "umbriel config.toml" || bad "umbriel config.toml missing"
[[ -f "$REPO/dotfiles/.local/state/noctalia/settings.toml" ]] && ok "noctalia seed settings" || bad "noctalia seed missing"
if command -v umbriel >/dev/null 2>&1; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  mkdir -p "$tmp/.config/umbriel"
  cp "$REPO/dotfiles/.config/umbriel/"*.toml "$tmp/.config/umbriel/" 2>/dev/null
  [[ -d "$REPO/dotfiles/.config/umbriel/shaders" ]] && cp -r "$REPO/dotfiles/.config/umbriel/shaders" "$tmp/.config/umbriel/"
  HOME="$tmp" XDG_CONFIG_HOME="$tmp/.config" umbriel config validate >/dev/null 2>&1 && ok "umbriel validates" || bad "umbriel config invalid"
  rm -rf "$tmp"; trap - EXIT
else
  echo "  skip: umbriel binary not on PATH"
fi

if [[ $FULL -eq 1 ]]; then
  echo "== full: flake eval + dry build (snapshot) =="
  snap="$(dot_snapshot)" || { bad "snapshot failed"; }
  if [[ -n "${snap:-}" ]]; then
    trap 'rm -rf "$snap"' EXIT INT TERM
    (cd "$snap" && nix flake show --no-write-lock-file >/dev/null 2>&1) && ok "flake show" || bad "flake show"
    (cd "$snap" && nix build "path:$snap#nixosConfigurations.nixos.config.system.build.toplevel" --no-link --dry-run 2>&1 | tail -2) && ok "dry build" || bad "dry build"
    rm -rf "$snap"
    trap - EXIT INT TERM
  fi
else
  echo "  (skip full build — use: dot check --full)"
fi

[[ $fail -eq 0 ]] && echo "check: all ok" || { echo "check: FAILED" >&2; exit 1; }
