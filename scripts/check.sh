#!/usr/bin/env bash
# check — read-only validation. Never mutates. Two tiers:
# fast (default): nix parse, required files, bundle names, defaults.toml
# roles, mime drift, symlink sanity, umbriel/noctalia config presence.
# full (--full): + flake evaluation + dry build via snapshot (expensive).
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
source "$REPO/scripts/lib.sh"
FULL=0 VERBOSE=0
for a in "$@"; do
  case "$a" in
    --full) FULL=1 ;;
    --verbose|-v) VERBOSE=1 ;;
  esac
done
fail=0
ok() { echo "  ok: $*"; }
bad() { echo "  FAIL: $*" >&2; fail=1; }
echo "== nix syntax =="
n_ok=0 n_bad=0
for f in flake.nix nix/home-entry.nix nix/machine/settings.nix nix/system/default.nix \
  nix/home/default.nix nix/home/programs/bundles.nix nix/home/programs/default.nix nix/home/shell/default.nix \
  nix/system/options.nix nix/desktop/umbriel/home.nix nix/desktop/umbriel/nixos.nix; do
  if nix-instantiate --parse "$REPO/$f" >/dev/null 2>&1; then n_ok=$((n_ok + 1)); [[ $VERBOSE -eq 1 ]] && ok "$f"; else bad "parse: $f"; n_bad=$((n_bad + 1)); fi
done
for m in "$REPO"/nix/system/*.nix "$REPO"/nix/machine/*.nix; do
  [[ "$(basename "$m")" == "local.nix" || "$(basename "$m")" == "hardware-configuration.nix" ]] && continue
  if nix-instantiate --parse "$m" >/dev/null 2>&1; then n_ok=$((n_ok + 1)); [[ $VERBOSE -eq 1 ]] && ok "$(basename "$m")"; else bad "parse: $m"; n_bad=$((n_bad + 1)); fi
done
[[ $VERBOSE -eq 0 ]] && echo "  ok: $n_ok files parsed"

echo "== required files =="
[[ -f "$REPO/flake.lock" ]] && ok "flake.lock" || bad "flake.lock missing"
[[ -f "$REPO/nix/machine/hardware-configuration.nix" || -f /etc/nixos/hardware-configuration.nix ]] \
  && ok "hardware config (repo or /etc/nixos)" || bad "no hardware config anywhere"
[[ -f "$REPO/config/defaults.toml" ]] && ok "config/defaults.toml" || bad "defaults.toml missing"

echo "== apps =="
if command -v nix >/dev/null 2>&1; then
  names="$(cd "$REPO" && nix eval --impure --json --expr "$DOT_CATALOG b.names" --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo FAIL)"
  [[ "$names" != "FAIL" ]] && ok "catalog readable" || bad "bundles.nix unreadable"
  for src in "$REPO/nix/machine/settings.nix" "$REPO/nix/machine/local.nix"; do
    [[ -f "$src" ]] || continue
    sel="$(cd "$REPO" && nix eval --impure --raw --expr "let v = import $src $(basename "$src" .nix | sed 's/.*/{lib={mkDefault=x:x;};}/'); in 1" --extra-experimental-features 'nix-command flakes' 2>/dev/null || true)"
    _=0
  done
  # validate selected app IDs against catalog (core implicit; legacy names ok)
  sel="$(cd "$REPO" && nix eval --impure --raw --expr 'builtins.concatStringsSep "," ((import ./nix/machine/settings.nix).bundles or [])' --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo "")"
  if [[ -f "$REPO/nix/machine/local.nix" ]]; then
    lsel="$(cd "$REPO" && nix eval --impure --raw --expr "$DOT_CATALOG (let l = import ./nix/machine/local.nix {lib={mkDefault=x:x;};}; in builtins.concatStringsSep \",\" (b.expandGroups (l.lysec.bundles or [])))" --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo "")"
    [[ -n "$lsel" ]] && sel="$lsel"
  fi
  if [[ -z "$sel" ]]; then
    ok "core only (no optional apps)"
  else
    IFS=',' read -ra _bs <<<"$sel"
    for b in "${_bs[@]}"; do
      [[ "$names" == *"\"$b\""* ]] && ok "app: $b" || bad "unknown app: $b"
    done
  fi
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
