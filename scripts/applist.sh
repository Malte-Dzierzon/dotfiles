#!/usr/bin/env bash
# applist.sh — lists installed apps (TUI & GUI) with source.
# Sources: repo (own .desktop files in dotfiles), nixpkgs (system profile),
#   flake (flake-input packages), appimage/bin (external binaries).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ui.sh"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_APPS="$REPO_DIR/dotfiles/.local/share/applications"

# Bundle map: pname -> core|<appid>|flake|-, generated from bundles.nix.
# Built lazily on first use; falls back to "-" when nix eval fails.
_BUNDLE_MAP=""
bundle_of() { # <pname-or-exec-token>: core|<appid>|flake|system|extra|-
  local key="$1"
  if [[ -z "$_BUNDLE_MAP" ]]; then
    _BUNDLE_MAP="$(cd "$REPO_DIR" && nix eval --impure --raw --expr 'let pkgs = import <nixpkgs> {}; lib = pkgs.lib; mkDummy = name: { packages = { x86_64-linux = { default = { pname = name; }; }; }; }; inputs = { zen-browser = mkDummy "zen"; concord = mkDummy "concord"; sonora = { packages = { x86_64-linux = { sonora-bin = { pname = "sonora"; }; }; }; }; omp = { packages = { x86_64-linux = { omp = { pname = "omp"; }; }; }; }; toofan = { packages = { x86_64-linux = { default = { pname = "toofan"; }; }; }; }; nixpkgs-unstable = { legacyPackages = { x86_64-linux = { godot = { pname = "godot"; }; }; }; }; noctalia = { packages = { x86_64-linux = { default = { pname = "noctalia"; }; }; }; }; }; b = import ./nix/home/programs/bundles.nix { inherit pkgs inputs lib; }; line = tag: ps: map (p: "${(p.pname or p.name)}:${tag}") ps; in builtins.concatStringsSep "\n" ((line "core" b.groups.core) ++ (builtins.concatMap (id: ["${id}:${id}"]) b.appIds))' --extra-experimental-features 'nix-command flakes' 2>/dev/null || true)"
  fi
  local hit
  hit="$(printf '%s' "$_BUNDLE_MAP" | grep -m1 -i "^${key}:" || true)"
  [[ -z "$hit" ]] && hit="$(printf '%s' "$_BUNDLE_MAP" | grep -m1 -i "^${key}-" || true)"
  if [[ -n "$hit" ]]; then printf '%s' "${hit#*:}"; else printf '-'; fi
}

# Flake inputs whose packages count as "flake" source (name -> input).
flake_pkgs="zen-browser omp toofan concord noctalia"
src_of() { # <desktop-file>: repo|nixpkgs|flake:...|bin
  local f="$1" exec_line byfile
  case "$f" in
    "$REPO_APPS"/*) echo "repo"; return ;;
  esac
  exec_line="$(grep -m1 '^Exec=' "$f" 2>/dev/null | cut -d= -f2- || true)"
  for fp in $flake_pkgs; do
    case "$exec_line" in *"$fp"*) echo "flake:$fp"; return ;; esac
  done
  case "$exec_line" in
    *".local/bin"*|*".AppImage"*|*"appimage"*) echo "bin"; return ;;
  esac
  # Filename -> source (Exec does not always contain the name,
  # e.g. Zen launches via wrapper script).
  case "$(basename "$f")" in
    *zen*|*Zen*) echo "flake:zen-browser"; return ;;
    *toofan*) echo "flake:toofan"; return ;;
    *concord*|*discord-1216669957799018608*) echo "flake:concord"; return ;;
    *noctalia*|*Noctalia*) echo "flake:noctalia"; return ;;
    *omp*|*oh-my-pi*) echo "flake:omp"; return ;;
  esac
  echo "nixpkgs"
}


is_tui() { # <desktop-file>: TUI when ConsoleOnly, tui wrapper, or terminal in foot/kitty.
  local f="$1" base exec_line
  base="$(basename "$f")"
  case "$base" in tui-*) return 0 ;; esac
  # Pure terminal emulators are GUI (the TUI only starts inside them).
  case "$base" in foot*.desktop|kitty*.desktop|alacritty*.desktop|ghostty*.desktop) return 1 ;; esac
  grep -qi 'ConsoleOnly' "$f" 2>/dev/null && return 0
  exec_line="$(grep -m1 '^Exec=' "$f" 2>/dev/null || true)"
  case "$exec_line" in *foot*|*tui-*) return 0 ;; esac
  return 1
}

collect() { # <dir>: name<TAB>source per visible .desktop
  local dir="$1" f name nodisp src hidden onlyshow
  [ -d "$dir" ] || return 0
  for f in "$dir"/*.desktop; do
    [ -f "$f" ] || continue
    nodisp="$(grep -m1 '^NoDisplay=' "$f" 2>/dev/null | cut -d= -f2 || true)"
    [ "$nodisp" = "true" ] && continue
    hidden="$(grep -m1 '^Hidden=' "$f" 2>/dev/null | cut -d= -f2 || true)"
    [ "$hidden" = "true" ] && continue
    onlyshow="$(grep -m1 '^OnlyShowIn=' "$f" 2>/dev/null | cut -d= -f2- || true)"
    # Portals/helpers with no launcher use filtered out (autostart, servers, demos).
    case "$(basename "$f")" in
      *-autorun-*.desktop|*-server.desktop|xdg-*.desktop|org.gtk.Demo*.desktop|org.gtk.*.desktop|foot-server.desktop|footclient.desktop|cups.desktop|*url-handler*.desktop) continue ;;
    esac
    name="$(grep -m1 '^Name=' "$f" 2>/dev/null | cut -d= -f2- || basename "$f" .desktop)"
    [ -n "$name" ] || continue
    src="$(src_of "$f")"
    printf '%s\t%s\t%s\n' "$name" "$src" "$f"
  done
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
collect "$REPO_APPS" >>"$tmp"
collect "/run/current-system/sw/share/applications" >>"$tmp"
collect "$HOME/.nix-profile/share/applications" >>"$tmp"
collect "/etc/profiles/per-user/$USER/share/applications" >>"$tmp"

print_group() { # <title> <0|1=tui>
  local title="$1" want_tui="$2" rows n=0 wid=0 line nm src
  rows="$(mktemp)"
  while IFS=$'\t' read -r nm src _f; do
    if is_tui "$_f"; then got=1; else got=0; fi
    [ "$got" = "$want_tui" ] || continue
    printf '%s\t%s\n' "$nm" "$src" >>"$rows"
    [ ${#nm} -gt "$wid" ] && wid=${#nm}
    n=$((n + 1))
  done <"$tmp"
  [ "$n" -eq 0 ] && { rm -f "$rows"; return; }
  ui_head "$title ($n)"
  # Dedup by name: repo entry wins (own wrappers with icon/WMClass).
  sort -u "$rows" | awk -F'\t' '{ if (!($1 in best) || $2=="repo") best[$1]=$2 } END { for (k in best) print k"\t"best[k] }' | sort | while IFS=$'\t' read -r nm src; do
    # bundle via exec token or name (lowercased, non-alnum stripped)
    key="$(printf '%s' "$nm" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]*//g')"
    bundle="$(bundle_of "$key")"
    if [[ "$bundle" == "-" ]]; then
      case "$key" in
        btop*) bundle="$(bundle_of btop)" ;;
        neovim|nvim|neovimwrapper) bundle="$(bundle_of neovim)" ;;
        godotengine*) bundle="$(bundle_of godot)" ;;
        zenbrowser|zen) bundle="flake" ;;
        lmstudio) bundle="flake" ;;
        opentabletdriver) bundle="system" ;;
        yazi|yazifilemanager) bundle="extra" ;;
        pi|picodingagent) bundle="$(bundle_of pi-coding-agent)" ;;
      esac
    fi
    printf '  %-*s  %-8s %s%s%s\n' "$wid" "$nm" "$bundle" "${__C_D}" "$src" "${__C_X}"
  done
  rm -f "$rows"
}

print_group "TUI apps" 1
print_group "GUI apps" 0
