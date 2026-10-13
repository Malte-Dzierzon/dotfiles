#!/usr/bin/env bash
# mode.sh — temporary/per-boot desktop ↔ headless switching.
# Temporary: `systemctl isolate multi-user.target` (headless) or
#   `graphical.target` (desktop). Ends GUI sessions; aborts if SSH is not
#   reachable-safe (no active sshd + headless request = refuse without --force).
# Persistent: `--default` sets the boot target via `systemctl set-default`.
# Never reboots on its own. Run from a local session for target switches.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=./lib.sh
source "$REPO/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage: dot mode status
       dot mode desktop [--default]
       dot mode headless [--default] [--force]

status            show default + current systemd target
desktop           isolate graphical.target now (--default: boot into it)
headless          isolate multi-user.target now (--default: boot into it)
  --force         skip the SSH safety check (you know another way back in)
EOF
}

ssh_safe() { systemctl is-active --quiet sshd 2>/dev/null; }

do_status() {
  local def cur
  def="$(systemctl get-default 2>/dev/null || echo ?)"
  # default.target is an alias (usually -> graphical.target); resolve it.
  if [[ "$def" == "default.target" ]]; then
    def="default.target (-> $(readlink /etc/systemd/system/default.target 2>/dev/null || echo ?))"
  fi
  echo "default: $def"
  cur="$(systemctl show -p SubState --value graphical.target 2>/dev/null || echo ?)"
  echo "graphical: $cur"
  systemctl is-active --quiet graphical.target && echo "desktop: ACTIVE" || echo "desktop: inactive"
  ssh_safe && echo "sshd: active" || echo "sshd: INACTIVE"
}

do_switch() {
  local target="$1" persistent=0 force=0
  shift
  for a in "$@"; do
    case "$a" in
      --default) persistent=1 ;;
      --force) force=1 ;;
      *) _dot_err "unknown flag: $a"; usage >&2; exit 1 ;;
    esac
  done
  if [[ "$target" == "multi-user.target" ]] && ! ssh_safe && [[ "$force" -eq 0 ]]; then
    _dot_err "sshd is not active — isolating headless could lock you out."
    _dot_err "Start sshd first, or retry with --force."
    exit 1
  fi
  if [[ "$persistent" -eq 1 ]]; then
    sudo systemctl set-default "$target"
    _dot_ok "boot default -> $target"
  else
    _dot_warn "isolating $target now (GUI sessions end; no reboot)"
    sudo systemctl isolate "$target"
  fi
}

cmd="${1:-status}"
case "$cmd" in
  status) do_status ;;
  desktop) do_switch graphical.target "${@:2}" ;;
  headless) do_switch multi-user.target "${@:2}" ;;
  -h | --help | help) usage ;;
  *) usage >&2; exit 1 ;;
esac
