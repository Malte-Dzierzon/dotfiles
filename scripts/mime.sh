#!/usr/bin/env bash
# mime — compare default-app roles with XDG MIME associations.
# Usage: dot mime [--fix]
#   default: report drift between config/defaults.toml roles (browser,
#     editor, file, pdf) and dotfiles/.config/mimeapps.list
#   --fix: rewrite the MIME entries for those roles from defaults.toml
#     (backs up the old file to *.bak-<timestamp> first)
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
ROLE="$REPO/config/defaults.toml"
MIME="$REPO/dotfiles/.config/mimeapps.list"
FIX=0; [[ "${1:-}" == "--fix" ]] && FIX=1

role() { sed 's/#.*//' "$ROLE" | awk -F= -v r="$1" '{gsub(/^[ \t]+|[ \t]+$/,"",$1)} $1==r {gsub(/^[ \t"]+|[ \t"]+$/,"",$2); print $2; exit}'; }
# Known .desktop names per binary (extend as new apps appear).
desktop_of() { case "$1" in
  zen) echo "zen.desktop" ;; firefox) echo "firefox.desktop" ;;
  zeditor|zed) echo "dev.zed.Zed.desktop" ;; nvim) echo "nvim.desktop" ;;
  code) echo "code.desktop" ;; nautilus) echo "org.gnome.Nautilus.desktop" ;;
  thunar) echo "thunar.desktop" ;; dolphin) echo "org.kde.dolphin.desktop" ;;
  zathura) echo "org.pwmt.zathura.desktop" ;; evince) echo "org.gnome.Evince.desktop" ;;
  okular) echo "org.kde.okular.desktop" ;; *) echo "$1.desktop" ;;
esac; }
mime_keys() { case "$1" in # roles worth mirroring into MIME
  browser) echo "x-scheme-handler/http x-scheme-handler/https text/html" ;;
  editor) echo "text/plain text/markdown application/json application/x-shellscript" ;;
  file) echo "inode/directory" ;;
  pdf) echo "application/pdf" ;;
esac; }

drift=0
for r in browser editor file pdf; do
  bin="$(role "$r")"; desk="$(desktop_of "$bin")"
  for key in $(mime_keys "$r"); do
    cur="$(grep -m1 -F -e "$key=" "$MIME" | cut -d= -f2- | cut -d\; -f1 || true)"
    if [[ "$cur" != "$desk" ]]; then
      echo "drift: [$r=$bin] $key: mime=$cur want=$desk"
      drift=1
    fi
  done
done
[[ $drift -eq 0 ]] && { echo "mime: in sync with defaults.toml"; exit 0; }
[[ $FIX -eq 0 ]] && { echo "fix with: dot mime --fix"; exit 1; }
cp "$MIME" "$MIME.bak-$(date +%Y%m%d-%H%M%S)"
for r in browser editor file pdf; do
  desk="$(desktop_of "$(role "$r")")"
  for key in $(mime_keys "$r"); do
    if grep -q "^$key=" "$MIME"; then
      sed -i "s|^$key=.*|$key=$desk|" "$MIME"
    else
      sed -i "/^\[Default Applications\]/a $key=$desk" "$MIME"
    fi
  done
done
echo "mime: updated from defaults.toml (backup kept)"
