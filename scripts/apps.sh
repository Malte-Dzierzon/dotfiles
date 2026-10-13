#!/usr/bin/env bash
# apps.sh — per-device bundle selection from the single catalog.
#
#   ./scripts/apps.sh [--list] [--dry-run]
#
# Reads bundle names + blurbs from home/programs/bundles.nix via nix eval
# (no second list). Shows current local.nix selection, offers toggle,
# writes ONLY lysec.bundles in hosts/nixos/local.nix (git-ignored —
# never touches other devices or the shared repo), then offers apply.
# Selection unit = bundle (simplest design covering desktop-vs-laptop).
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ui.sh"

LIST_ONLY=0 DRY_RUN=0
for a in "$@"; do
  case "$a" in
    --list) LIST_ONLY=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h | --help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown: $a" >&2; exit 1 ;;
  esac
done

command -v nix >/dev/null 2>&1 || { _dot_err "nix not found."; exit 1; }

if command -v jq >/dev/null 2>&1; then _jq() { jq "$@"; }; else _jq() { nix --extra-experimental-features 'nix-command flakes' run nixpkgs#jq -- "$@"; }; fi
NAMES="$(cd "$REPO" && nix eval --impure --json --expr \
  '(import ./home/programs/bundles.nix {pkgs=null; inputs={}; lib={};}).names' \
  --extra-experimental-features 'nix-command flakes' 2>/dev/null | _jq -r '.[]' 2>/dev/null)" \
  || { _dot_err "Catalog unreadable (bundles.nix)."; exit 1; }

blurb_of() {
  cd "$REPO" && nix eval --impure --raw --expr \
    "(import ./home/programs/bundles.nix {pkgs=null; inputs={}; lib={};}).blurbs.$1 or \"\"" \
    --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo ""
}
current_csv() {
  [[ -f "$REPO/hosts/nixos/local.nix" ]] || { echo ""; return; }
  cd "$REPO" && nix eval --impure --raw --expr \
    'let l = import ./hosts/nixos/local.nix {lib = {mkDefault = x: x;};}; in builtins.concatStringsSep "," (l.lysec.bundles or [])' \
    --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo ""
}

CUR="$(current_csv)"
FROM_DEFAULTS=0
if [[ -z "$CUR" ]]; then
  CUR="$(cd "$REPO" && nix eval --impure --raw --expr \
    'builtins.concatStringsSep "," ((import ./hosts/nixos/settings.nix).bundles or [])' \
    --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo "core")"
  FROM_DEFAULTS=1
  _dot_warn "no bundle selection in local.nix — showing settings.nix defaults (Enter keeps them)."
fi

ui_head "app catalog (local: $CUR)"
while read -r b; do
  [[ -z "$b" ]] && continue
  if [[ ",$CUR," == *",$b,"* ]]; then
    printf '  [x] %-10s %s%s%s\n' "$b" "${__C_D}" "$(blurb_of "$b")" "${__C_X}"
  else
    printf '  [ ] %-10s %s%s%s\n' "$b" "${__C_D}" "$(blurb_of "$b")" "${__C_X}"
  fi
done <<<"$NAMES"

[[ $LIST_ONLY -eq 1 ]] && exit 0

# Self-contained numbered multiselect (wizard is NOT sourced: it executes on source).
multiselect() { # <preselected-csv> <opt...>: prints csv, empty+rc1 = back.
  local pre="$1"; shift
  local opts=("$@") i o raw sel=() n out=""
  echo "" >&2
  i=0
  for o in "${opts[@]}"; do
    i=$((i + 1))
    if [[ ",$pre," == *",$o,"* ]]; then printf '  %d) [x] %s\n' "$i" "$o" >&2; else printf '  %d) [ ] %s\n' "$i" "$o" >&2; fi
  done
  printf 'Numbers, comma-separated (Enter = keep, 0 = abort): ' >&2
  IFS= read -r raw || return 1
  [[ -z "$raw" ]] && { printf '%s' "$pre"; return 0; }
  [[ "$raw" == "0" ]] && return 1
  IFS=',' read -ra sel <<<"$raw"
  for n in "${sel[@]}"; do
    n="${n// /}"
    [[ "$n" =~ ^[0-9]+$ ]] && ((n >= 1 && n <= ${#opts[@]})) || return 1
    out+="${opts[$((n - 1))]},"
  done
  printf '%s' "${out%,}"
}
NEW="$(multiselect "$CUR" $NAMES)" || {
  _dot_warn "Aborted — nothing written."
  exit 1
}

[[ -z "$NEW" ]] && { _dot_err "Empty selection — at least one bundle (core recommended)."; exit 1; }

if [[ "$NEW" == "$CUR" && $FROM_DEFAULTS -eq 0 ]]; then
  _dot_ok "Unchanged ($CUR)."
  exit 0
fi

echo "---"
echo "old: $CUR"
echo "new: $NEW"
echo "Writes only lysec.bundles in hosts/nixos/local.nix (git-ignored, this device only)."
if [[ $DRY_RUN -eq 1 ]]; then
  echo "dry-run: nothing written."
  exit 0
fi
printf 'Apply? [y/N]: '
IFS= read -r ans || exit 1
[[ "$ans" == [yYjJ]* ]] || { echo "aborted."; exit 1; }

# Minimal edit: only the bundles line block in local.nix; keep all other keys.
TMP="$(mktemp)"
bundle_lines=""
IFS=',' read -ra _bs <<<"$NEW"
for b in "${_bs[@]}"; do bundle_lines+="    \"$b\"\n"; done
if [[ -f "$REPO/hosts/nixos/local.nix" ]]; then
  # Replace the bundles block; if missing (old local.nix without bundles), insert before
  # the closing brace of lysec. Other keys stay untouched.
  python3 - "$REPO/hosts/nixos/local.nix" "$bundle_lines" >"$TMP" <<'EOF' || exit 1
import re, sys
src = open(sys.argv[1]).read()
new_items = sys.argv[2].replace('\\n', '\n').rstrip('\n')
new_block = "bundles = [\n" + new_items + "\n    ];"
out, n = re.subn(r'bundles\s*=\s*\[.*?\]', new_block, src, flags=re.S)
if n == 0:
    # No bundles key (old local.nix): insert before the last "};" of the
    # lysec block. Other keys stay untouched.
    m = re.search(r'\n([ ]*)\};\s*\n\}\s*$', src)
    if not m:
        sys.stderr.write("XX lysec block not found in local.nix — check the file.\n")
        sys.exit(1)
    indent = m.group(1) + "  "
    lines = "".join(indent + "  " + l.strip() + "\n" for l in new_items.split("\n"))
    insert = "\n" + indent + "bundles = [\n" + lines + indent + "];" + m.group(0)
    out = src[:m.start()] + insert + src[m.end():]
    n = 1
if n != 1:
    sys.stderr.write("XX bundles block not found in local.nix — check the file.\n")
    sys.exit(1)
sys.stdout.write(out)
EOF
  cp "$TMP" "$REPO/hosts/nixos/local.nix"
else
  _dot_err "no local.nix — run ./install.sh first."
  exit 1
fi
rm -f "$TMP"
_dot_ok "local.nix bundles = [$NEW]"

printf 'Apply now (apply.sh dry-build + switch)? [y/N]: '
IFS= read -r ans2 || exit 0
[[ "$ans2" == [yYjJ]* ]] && exec "$REPO/scripts/apply.sh"
echo "Selection saved, NOT active. Apply: ./scripts/apply.sh"
