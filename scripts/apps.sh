#!/usr/bin/env bash
# apps.sh — per-app selection from the single catalog.
#
#   ./scripts/apps.sh [--list] [--dry-run]
#
# Reads app IDs + blurbs from nix/home/programs/bundles.nix via nix eval
# (no second list). Shows current local.nix selection, offers toggles,
# writes ONLY lysec.bundles in nix/machine/local.nix (git-ignored —
# never touches other devices or the shared repo), then offers apply.
# Core is mandatory/implicit (never stored, never offered).
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ui.sh"
# shellcheck source=pick.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pick.sh"

LIST_ONLY=0 DRY_RUN=0
for a in "$@"; do
  case "$a" in
    --list) LIST_ONLY=1 ;;
    --dry-run) DRY_RUN=1 ;;
    *) echo "XX unknown flag: $a" >&2; exit 2 ;;
  esac
done

command -v nix >/dev/null 2>&1 || { _dot_err "nix not found."; exit 1; }
# CATEXPR retired: use $DOT_CATALOG from lib.sh (NIX_PATH-independent).
if ! NAMES_CSV="$(cd "$REPO" && nix eval --impure --raw --expr "$DOT_CATALOG builtins.concatStringsSep \",\" b.appIds" --extra-experimental-features 'nix-command flakes' 2>/dev/null)"; then
  _dot_err "Catalog unreadable (bundles.nix)."
  exit 1
fi
NAMES="${NAMES_CSV//,/ }"
blurb_of() {
  cd "$REPO" && nix eval --impure --raw --expr \
    "$DOT_CATALOG b.apps.$1.blurb or \"\"" \
    --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo ""
}
current_csv() {
  [[ -f "$REPO/nix/machine/local.nix" ]] || { echo ""; return; }
  cd "$REPO" && nix eval --impure --raw --expr \
    "$DOT_CATALOG (let l = import ./nix/machine/local.nix {lib = {mkDefault = x: x;};}; in builtins.concatStringsSep \",\" (b.expandGroups (l.lysec.bundles or [])))" \
    --extra-experimental-features 'nix-command flakes' 2>/dev/null || echo ""
}

CUR="$(current_csv)"
FROM_DEFAULTS=0
if [[ -z "$CUR" ]]; then
  _dot_warn "no app selection in local.nix — core only (Enter keeps it)."
  FROM_DEFAULTS=1
fi

ui_head "optional apps (core always on; local: ${CUR:-none})"
# shellcheck disable=SC2207
for b in $NAMES; do
  [[ -z "$b" ]] && continue
  if [[ ",$CUR," == *",$b,"* ]]; then
    printf '  [x] %-16s %s%s%s\n' "$b" "${__C_D}" "$(blurb_of "$b")" "${__C_X}"
  else
    printf '  [ ] %-16s %s%s%s\n' "$b" "${__C_D}" "$(blurb_of "$b")" "${__C_X}"
  fi
done

[[ $LIST_ONLY -eq 1 ]] && exit 0

# Interactive checkbox list. No TTY (pipe/CI) -> keep current.
multiselect() { # <preselected-csv> <opt...>: prints csv, empty+rc1 = back.
  local pre="$1"; shift
  [[ -t 0 && -e /dev/tty ]] || { printf '%s' "$pre"; return 0; }
  local out=""
  out="$(pick_multi "Applications (Space toggles, Core always on)" "Up/Down move · Space toggle · Enter ok · Esc abort" "$pre" "$@")" || return 1
  printf '%s' "$out"
}
# shellcheck disable=SC2207
NEW="$(multiselect "$CUR" $NAMES)" || {
  _dot_warn "Aborted — nothing written."
  exit 1
}

if [[ "$NEW" == "$CUR" && $FROM_DEFAULTS -eq 0 ]]; then
  echo "unchanged."
  exit 0
fi

echo "---"
echo "old: ${CUR:-none}"
echo "new: ${NEW:-none (core only)}"
echo "Writes only lysec.bundles in nix/machine/local.nix (git-ignored, this device only)."
if [[ $DRY_RUN -eq 1 ]]; then
  echo "dry-run: NOT written."
  exit 0
fi
printf 'Apply? [y/N]: '
IFS= read -r ans || exit 1
[[ "$ans" == [yYjJ]* ]] || { echo "aborted."; exit 1; }

# Minimal edit: only the bundles block in local.nix; keep all other keys.
TMP="$(mktemp)"
bundle_lines=""
IFS=',' read -ra _bs <<<"$NEW"
for b in ${_bs[@]+"${_bs[@]}"}; do
  [[ -z "$b" ]] && continue
  bundle_lines+="    \"$b\"\n"
done
if [[ -f "$REPO/nix/machine/local.nix" ]]; then
  python3 - "$REPO/nix/machine/local.nix" "$bundle_lines" >"$TMP" <<'PYEOF' || exit 1
import re, sys
src = open(sys.argv[1]).read()
new_items = sys.argv[2].replace('\\n', '\n').rstrip('\n')
new_block = "bundles = [\n" + new_items + "\n    ];"
out, n = re.subn(r'bundles\s*=\s*\[.*?\]', new_block, src, flags=re.S)
if n != 1:
    sys.stderr.write("XX bundles block not found in local.nix — check the file.\n")
    sys.exit(1)
sys.stdout.write(out)
PYEOF
  mv "$TMP" "$REPO/nix/machine/local.nix"
else
  _dot_err "nix/machine/local.nix missing — run the installer first."
  rm -f "$TMP"
  exit 1
fi
rm -f "$TMP"
_dot_ok "local.nix bundles = [${NEW:-none (core only)}]"

printf 'Apply now (apply.sh dry-build + switch)? [y/N]: '
IFS= read -r ans2 || exit 0
[[ "$ans2" == [yYjJ]* ]] && exec "$REPO/scripts/apply.sh"
echo "Selection saved, NOT active. Apply: ./scripts/apply.sh"
