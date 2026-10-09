#!/usr/bin/env bash
# install-wizard.sh — interactive, keyboard-driven installer.
#
# Modes:
#   install-wizard.sh --live    Minimal ISO: TUI -> local.nix -> nixos-install --root /mnt
#   install-wizard.sh --apply   installed NixOS: TUI -> local.nix -> validate -> rebuild
#   install-wizard.sh --check   reserviert (derzeit no-op; apply.sh nutzt lib.sh-Preflights direkt)
#
# TUI: gum if present (progressive enhancement), else dialog, else pure-bash
# numbered menus. All three work over plain TTYSSH with keyboard only.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

MODE="${1:---apply}"
HAVE_GUM=0 HAVE_DIALOG=0
command -v gum >/dev/null 2>&1 && HAVE_GUM=1
command -v dialog >/dev/null 2>&1 && HAVE_DIALOG=1
# Echter TTY-Check per open-Probe (-r/-c luegen unter Pipes/CI).
HAVE_TTY=0
{ : </dev/tty; } 2>/dev/null && HAVE_TTY=1

# --- tiny TUI layer ---------------------------------------------------------
# _menu <title> <prompt> <default> <opt...> -> prints choice to stdout.
# Back/cancel: empty output + return 1.
_menu() {
  local title="$1" prompt="$2" def="$3"
  shift 3
  local opts=("$@") i choice=""
  # _tty_read: /dev/tty bevorzugt, stdin als Fallback (Pipes/Tests).
  _tty_read() {
    if [[ $HAVE_TTY -eq 1 ]] && IFS= read -r "$1" </dev/tty 2>/dev/null; then return 0; fi
    IFS= read -r "$1" || return 1
  }
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then
    choice="$(gum choose --header "$title — $prompt (Esc = zurueck)" --selected "$def" "${opts[@]}" </dev/tty 2>/dev/null)" && [[ -n "$choice" ]] && {
      printf '%s' "$choice"
      return 0
    }
    # gum da, aber kein TTY (Pipe/CI) — falle auf Textmenue zurueck statt still abzubrechen.
  fi
  if [[ $HAVE_DIALOG -eq 1 && $HAVE_TTY -eq 1 ]]; then
    local args=() n=0
    for o in "${opts[@]}"; do
      n=$((n + 1))
      if [[ "$o" == "$def" ]]; then args+=("$n" "$o" "on"); else args+=("$n" "$o" "off"); fi
    done
    # dialog: UI -> /dev/tty, Wahl (stderr) -> capture. Reihenfolge ist Absicht (SC2327/2328-Ausnahme).
    # shellcheck disable=SC2327,SC2328
    choice="$(dialog --clear --backtitle "dotfiles installer" --title "$title" \
      --radiolist "$prompt (Abbrechen = zurueck)" 16 60 "$n" "${args[@]}" 2>&1 >/dev/tty </dev/tty)" && [[ -n "$choice" ]] && {
      printf '%s' "${opts[$((choice - 1))]}"
      return 0
    }
  fi
  _bash_menu() {
    printf '\n=== %s ===\n%s\n' "$title" "$prompt" >&2
    i=0
    for o in "${opts[@]}"; do
      i=$((i + 1))
      if [[ "$o" == "$def" ]]; then printf '  %d) %s  [default]\n' "$i" "$o" >&2; else printf '  %d) %s\n' "$i" "$o" >&2; fi
    done
    printf '  0) zurueck\nWahl [default=%s]: ' "$def" >&2
    _tty_read choice || return 1
    if [[ -z "$choice" ]]; then printf '%s' "$def"; return 0; fi
    if [[ "$choice" == "0" ]]; then return 1; fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#opts[@]})); then
      printf '%s' "${opts[$((choice - 1))]}"
      return 0
    fi
    return 1
  }
  _bash_menu
}

# _ask <title> <prompt> <default> -> prints answer; empty keeps default.
_ask() {
  local title="$1" prompt="$2" def="$3" ans=""
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then
    ans="$(gum input --header "$title" --prompt "$prompt " --value "$def" </dev/tty 2>/dev/null)" && {
      printf '%s' "${ans:-$def}"
      return 0
    }
  fi
  printf '\n=== %s ===\n%s [default=%s]: ' "$title" "$prompt" "$def" >&2
  if [[ $HAVE_TTY -eq 1 ]] && IFS= read -r ans </dev/tty 2>/dev/null; then :; else IFS= read -r ans || return 1; fi
  printf '%s' "${ans:-$def}"
}

# _confirm <text> -> return 0 on yes.
_confirm() {
  local text="$1" ans=""
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then
    gum confirm "$text" </dev/tty 2>/dev/null
    return $?
  fi
  if [[ $HAVE_DIALOG -eq 1 && $HAVE_TTY -eq 1 ]]; then
    dialog --clear --backtitle "dotfiles installer" --yesno "$text" 10 60 >/dev/tty 2>&1 </dev/tty
    return $?
  fi
  printf '%s [j/N]: ' "$text" >&2
  if [[ $HAVE_TTY -eq 1 ]] && IFS= read -r ans </dev/tty 2>/dev/null; then :; else IFS= read -r ans || return 1; fi
  [[ "$ans" == [jJyY]* ]]
}

# _multiselect <title> <prompt> <preselected-csv> <opt...> -> prints csv.
_multiselect() {
  local title="$1" prompt="$2" pre="$3"
  shift 3
  local opts=("$@") out=""
  if [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]]; then
    local args=()
    for o in "${opts[@]}"; do
      if [[ ",$pre," == *",$o,"* ]]; then args+=("--selected=$o"); fi
    done
    if out="$(gum choose --no-limit --header "$title — $prompt (Space = togglen, Enter = ok)" "${args[@]}" "${opts[@]}" </dev/tty 2>/dev/null)" && [[ -n "$out" ]]; then
      printf '%s' "$out" | tr '\n' ',' | sed 's/,$//'
      return 0
    fi
  fi
  printf '\n=== %s ===\n%s\nNummern mit Komma trennen (z.B. 1,3,4), 0 = zurueck:\n' "$title" "$prompt" >&2
  local i=0
  for o in "${opts[@]}"; do
    i=$((i + 1))
    if [[ ",$pre," == *",$o,"* ]]; then printf '  %d) [x] %s\n' "$i" "$o" >&2; else printf '  %d) [ ] %s\n' "$i" "$o" >&2; fi
  done
  printf 'Wahl: ' >&2
  local raw sel=() n
  if [[ $HAVE_TTY -eq 1 ]] && IFS= read -r raw </dev/tty 2>/dev/null; then :; else IFS= read -r raw || return 1; fi
  [[ "$raw" == "0" ]] && return 1
  IFS=',' read -ra sel <<<"$raw"
  out=""
  for n in "${sel[@]}"; do
    n="${n// /}"
    [[ "$n" =~ ^[0-9]+$ ]] && ((n >= 1 && n <= ${#opts[@]})) || return 1
    out+="${opts[$((n - 1))]},"
  done
  printf '%s' "${out%,}"
}

# --- collected answers (defaults = current settings.nix) --------------------
_banner() {
  local backend="textmenue (bash)"
  [[ $HAVE_GUM -eq 1 && $HAVE_TTY -eq 1 ]] && backend="gum"
  [[ $HAVE_DIALOG -eq 1 && $backend == "textmenue (bash)" && $HAVE_TTY -eq 1 ]] && backend="dialog"
  cat >&2 <<EOF
=== dotfiles installer ($MODE, rev $(dot_current_rev), UI: $backend) ===
Tastatur: de/us/gb waehlen — gilt fuer Konsole + XKB + Greeter + Umbriel.
0 bzw. Esc = Schritt zurueck/Abbruch. Es wird NICHTS veraendert bis zur
finalen Bestaetigung (Review-Screen).
EOF
}
KBD="de" PROFILE="laptop" USERNAME="xealom" HOSTNAME="nixos"
TIMEZONE="Europe/Berlin" MAINLOCALE="en_US.UTF-8" REGIONAL="de_DE.UTF-8"
BUNDLES="core,terminal,editor,desktop,browser,dev,latex,notes,media,gaming,chat,net,fun"
GITNAME="Malte Dzierzon" GITEMAIL="malte@dzierzon.example"
CUSTOM_KBD="" TARGET_DISK="" WIPE_MODE="manual"

ALL_BUNDLES=(core terminal editor desktop browser dev latex notes media gaming chat net fun)

step_keyboard() {
  local c
  c="$(_menu "Tastatur" "Physisches Layout waehlen:" "$KBD" \
    "de — Deutsch QWERTZ" "us — US-Englisch QWERTY" "gb — UK-Englisch QWERTY" "custom — anderes (xkbcli-Name)")" || return 1
  case "$c" in
    de*) KBD="de" ;;
    us*) KBD="us" ;;
    gb*) KBD="gb" ;;
    custom*)
      CUSTOM_KBD="$(_ask "Tastatur" "XKB-Layout-Name (xkbcli list, z.B. fr, neo):" "fr")" || return 1
      KBD="$CUSTOM_KBD"
      _dot_warn "Custom-Layout: Console-Keymap = XKB-Name angenommen. Bei Divergenz local.nix anpassen (consoleKeyMap)."
      ;;
  esac
}

step_profile() {
  local c
  c="$(_menu "Profil" "Maschinentyp (steuert nur Quirks, nie Hardware-Erkennung):" "$PROFILE" \
    "laptop — eDP-Panel, intel_vbtn-Quirk, Powersaving" \
    "desktop — keine Laptop-Quirks, externe Outputs")" || return 1
  PROFILE="${c%% *}"
}

step_identity() {
  USERNAME="$(_ask "Identitaet" "Username:" "$USERNAME")" || return 1
  HOSTNAME="$(_ask "Identitaet" "Hostname:" "$HOSTNAME")" || return 1
  TIMEZONE="$(_ask "Identitaet" "Zeitzone (IANA, z.B. Europe/Berlin):" "$TIMEZONE")" || return 1
  MAINLOCALE="$(_ask "Identitaet" "System-Locale (i18n.defaultLocale):" "$MAINLOCALE")" || return 1
  REGIONAL="$(_ask "Identitaet" "Regionales LC_*-Buendel:" "$REGIONAL")" || return 1
  GITNAME="$(_ask "Identitaet" "Git user.name:" "$GITNAME")" || return 1
  GITEMAIL="$(_ask "Identitaet" "Git user.email:" "$GITEMAIL")" || return 1
  [[ "$USERNAME" =~ ^[a-z][a-z0-9_-]*$ ]] || {
    _dot_warn "Username '$USERNAME' ist ungueltig (klein, [a-z0-9_-])."
    return 1
  }
  # Hostname (RFC 1035-kurz): sonst schreibt Nix einen ungueltigen networking.hostName.
  [[ "$HOSTNAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || {
    _dot_warn "Hostname '$HOSTNAME' ist ungueltig (klein, alphanumerisch, Bindestriche innen)."
    return 1
  }
  # Nix-Injection-Schutz: keine ", \, $ in Freitext (local.nix-Stringliterale).
  local f
  for f in HOSTNAME TIMEZONE MAINLOCALE REGIONAL GITNAME GITEMAIL; do
    [[ "${!f}" != *['"'\$]* ]] || {
      _dot_warn "Ungueltiges Zeichen in $f (kein \", \\, \$ erlaubt)."
      return 1
    }
  done
  # Zeitzone gegen zoneinfo pruefen, falls lesbar (ISO/NixOS: /usr/share/zoneinfo).
  if [[ -d /usr/share/zoneinfo && ! -e "/usr/share/zoneinfo/$TIMEZONE" ]]; then
    _dot_warn "Zeitzone '$TIMEZONE' nicht in /usr/share/zoneinfo gefunden."
    return 1
  fi
}

step_bundles() {
  local csv
  csv="$(_multiselect "Anwendungen" "Bundles waehlen (shell+greeter immer an):" "$BUNDLES" "${ALL_BUNDLES[@]}")" || return 1
  [[ -z "$csv" ]] && {
    _dot_warn "Mindestens ein Bundle waehlen (core empfohlen)."
    return 1
  }
  BUNDLES="$csv"
}

# console keymap mapping (single place; mirrors modules/lysec/options.nix).
_console_for() {
  case "$1" in
    de) printf 'de' ;;
    us) printf 'us' ;;
    gb) printf 'uk' ;;
    *) printf '%s' "$1" ;;
  esac
}

# write local.nix from answers (generated category; never committed).
write_local_nix() {
  local bundle_lines b
  bundle_lines=""
  IFS=',' read -ra _bs <<<"$BUNDLES"
  local last="${_bs[${#_bs[@]}-1]}"
  for b in "${_bs[@]}"; do bundle_lines+="    \"$b\""; [[ "$b" != "$last" ]] && bundle_lines+=$'\n'; done
  cat >"$REPO/hosts/nixos/local.nix" <<EOF
# Erzeugt von scripts/install-wizard.sh ($MODE) am $(date -u +%F) — pro Maschine, git-ignoriert.
# Aendern: Datei editieren + scripts/apply.sh. Upstream-Updates per scripts/update.sh --pull; sie ruehren diese Datei nie an.
{lib, ...}: {
  lysec = {
    username = "$USERNAME";
    hostname = "$HOSTNAME";
    keyboardLayout = "$KBD";
    consoleKeyMap = "$(_console_for "$KBD")";
    profile = "$PROFILE";
    timezone = "$TIMEZONE";
    mainLocale = "$MAINLOCALE";
    regionalLocale = "$REGIONAL";
    bundles = [
$bundle_lines
    ];
    git.name = "$GITNAME";
    git.email = "$GITEMAIL";
  };
}
EOF
  _dot_ok "local.nix geschrieben (keyboard $KBD/console $(_console_for "$KBD"), profil $PROFILE)."
}

review_screen() {
  cat >&2 <<EOF

================ INSTALLATIONS-PLAN ================
  Modus:      $MODE
  Revision:   $(dot_current_rev)
  Tastatur:   $KBD  (XKB) / $(_console_for "$KBD") (Konsole) — gilt fuer Kernel, XKB, Greeter, Umbriel (folgt System)
  Profil:     $PROFILE
  User@Host:  $USERNAME@$HOSTNAME
  Zeitzone:   $TIMEZONE
  Locales:    $MAINLOCALE / $REGIONAL
  Bundles:    $BUNDLES
  Git:        $GITNAME <$GITEMAIL>
EOF
  if [[ "$MODE" == "--live" ]]; then
    cat >&2 <<EOF
  Ziel:       $TARGET_DISK ($WIPE_MODE)
  /mnt:       muss vorbereitet sein (partitioniert, formatiert, gemountet)
  Hardware:   wird per nixos-generate-config --root /mnt erzeugt (nie kopiert)
EOF
  else
    echo "  Wirkung:    local.nix schreiben, dry-build, dann nixos-rebuild switch" >&2
  fi
  echo "==================================================" >&2
}

# --- live-only: disk inspection (NEVER destructive here) ---------------------
step_disk() {
  echo >&2
  _dot_warn "Festplatten-Uebersicht (nur Anzeige — partitioniert wird hier NICHT):"
  lsblk -d -o NAME,MODEL,SIZE,TYPE,TRAN 2>/dev/null >&2 || lsblk -d >&2
  echo >&2
  lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT 2>/dev/null | head -n 30 >&2
  echo >&2
  local c
  c="$(_menu "Installation" "Installationsweg:" "manual" \
    "manual — /mnt ist vorbereitet, nur nixos-install ausfuehren" \
    "abort — erst manuell partitionieren (Anleitung zeigen)")" || return 1
  if [[ "$c" == abort* ]]; then
    cat >&2 <<'EOF'

Manuelle Vorbereitung (Beispiel EINZELPLATTE — Geraet anpassen!):
  sudo parted /dev/<disk> -- mklabel gpt mkpart ESP fat32 1MiB 1GiB mkpart root ext4 1GiB 100% set 1 esp on
  sudo mkfs.fat -F32 /dev/<disk>1 && sudo mkfs.ext4 -L nixos /dev/<disk>2
  sudo mount /dev/disk/by-label/nixos /mnt && sudo mkdir -p /mnt/boot && sudo mount /dev/<disk>1 /mnt/boot
  Danach Wizard erneut starten.
EOF
    return 1
  fi
  WIPE_MODE="manual"
  TARGET_DISK="$(_ask "Installation" "Ziel-Geraet zur Anzeige (z.B. /dev/nvme0n1, nur Doku — nichts wird formatiert):" "/dev/nvme0n1")" || return 1
  mountpoint -q /mnt || {
    _dot_warn "/mnt ist nicht gemountet — erst vorbereiten (s.o.), dann fortfahren."
    return 1
  }
  mountpoint -q /mnt/boot || _dot_warn "/mnt/boot nicht gemountet — EFI-Boot schlaegt fehl, wenn das Absicht ist ignorieren."
}

# --- run modes ----------------------------------------------------------------
run_live() {
  _banner
  step_keyboard || return 1
  step_profile || return 1
  step_identity || return 1
  step_bundles || return 1
  step_disk || return 1
  review_screen
  _confirm "In /mnt installieren (nixos-install --flake $REPO#nixos)? Bisher wurde NICHTS veraendert." || {
    _dot_warn "Abgebrochen vor jeder Systemaenderung."
    return 1
  }
  write_local_nix
  _dot_log "erzeuge Hardware-Config aus dem Zielsystem (nie aus dem Repo kopiert)..."
  sudo nixos-generate-config --root /mnt --show-hardware-config \
    | sudo tee "$REPO/hosts/nixos/hardware-configuration.nix" >/dev/null \
    || {
      _dot_err "nixos-generate-config fehlgeschlagen."
      return 1
    }
  grep -q 'fileSystems' "$REPO/hosts/nixos/hardware-configuration.nix" || {
    _dot_err "Generierte Config enthaelt keine fileSystems — Abbruch."
    return 1
  }
  _dot_log "dry-build (nix eval, schreibt nichts nach /mnt)..."
  dot_with_hw_staged nix --extra-experimental-features 'nix-command flakes' eval --raw "$REPO#nixosConfigurations.nixos.config.system.build.toplevel.drvPath" >/dev/null || {
    _dot_err "Dry-build fehlgeschlagen — Fehler oben beheben, keine Installation gestartet."
    return 1
  }
  _dot_warn "Letzte Chance: nixos-install installiert das System in /mnt (auf $TARGET_DISK laut deiner Vorbereitung)."
  _confirm "WIRKLICH installieren? Alle Daten auf den /mnt-Partitionen werden uebernommen/ueberschrieben." || {
    _dot_warn "Abgebrochen — /mnt und Repo unveraendert (local.nix + hardware-configuration.nix liegen im Checkout)."
    return 1
  }
  sudo nixos-install --root /mnt --flake "$REPO#nixos" --no-root-password || {
    _dot_err "nixos-install fehlgeschlagen — /mnt pruefen, Anleitung in README (Recovery)."
    return 1
  }
  cat >&2 <<EOF

Erstboot:
  1. sudo reboot, USB-Stick entfernen, ins installierte System booten.
  2. Als $USERNAME einloggen (Passwort: noch setzen — siehe unten).
  3. WLAN/Netz pruefen, dann: cd ~/Projects/dotfiles (frisch klonen) && ./scripts/apply.sh
  Root-Passwort ist deaktiviert (--no-root-password); User-Passwort nach dem
  ersten Boot per 'passwd' setzen bzw. im nixos-enter bereits erledigt.
EOF
}

run_apply() {
  _banner
  step_keyboard || return 1
  step_profile || return 1
  step_identity || return 1
  step_bundles || return 1
  review_screen
  _confirm "local.nix schreiben und $REPO#nixos per nixos-rebuild aktivieren?" || {
    _dot_warn "Abgebrochen — nichts geschrieben, nichts rebuildet."
    return 1
  }
  write_local_nix
  exec "$REPO/scripts/apply.sh"
}

case "$MODE" in
  --live) run_live ;;
  --apply) run_apply ;;
  *) echo "usage: $0 [--live|--apply]" >&2; exit 1 ;;
esac
rc=$?
if [[ $rc -ne 0 ]]; then
  _dot_warn "Wizard beendet ohne Aenderung (Abbruch oder Eingabefehler)."
fi
exit $rc
