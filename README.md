<div align="center">

# dotfiles

**NixOS + Umbriel + Noctalia — one flake, one theme source.**

![](https://img.shields.io/github/last-commit/Malte-Dzierzon/dotfiles?&style=flat-square&color=8ad7eb&logo=git&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/NixOS-26.05-5277C3?style=flat-square&logo=nixos&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/Umbriel-compositor-D55C44?style=flat-square&logo=wayland&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/Noctalia-shell-0e0e43?style=flat-square&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/Zed-editor-084D93?style=flat-square&logo=zed&logoColor=D9E0EE&labelColor=1E202B)

<img src="assets/screenshots/desktop.png" alt="desktop" width="750">

</div>

## Install

NixOS 26.05, x86_64. Vier Modi — frisch installieren, anwenden, updaten,
pruefen. `install.sh` bleibt als Shim (`--dry-run/--no-rebuild/--wizard/
--verify-only` → unten).

### Modus 1 — Fresh install von der Minimal-ISO (Ziel: /mnt)

1. Minimale ISO booten (UEFI), Netz verbinden (`nmtui`).
2. `/mnt` vorbereiten (Beispiel Einzelplatte — Geraet anpassen, LOESCHT Daten
   auf diesen Partitionen):
   ```bash
   sudo parted /dev/<disk> -- mklabel gpt mkpart ESP fat32 1MiB 1GiB mkpart root ext4 1GiB 100% set 1 esp on
   sudo mkfs.fat -F32 /dev/<disk>1 && sudo mkfs.ext4 -L nixos /dev/<disk>2
   sudo mount /dev/disk/by-label/nixos /mnt && sudo mkdir -p /mnt/boot && sudo mount /dev/<disk>1 /mnt/boot
   ```
3. Wizard starten (nur DIESER Code laeuft aus dem Netz — ~60 Zeilen lesbar,
   alles Privilegierte passiert danach aus dem geclonten Checkout):
   ```bash
   REF=<commit-sha>; bash <(curl --proto '=https' --tlsv1.2 -fsSL \
     https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/$REF/scripts/live-installer.sh)
   ```
   (`REF` pinnt die Revision; `main` floatet. Ohne REF keine Reproduzierbarkeit.)
4. Der Wizard fragt: **Tastatur** (de/us/gb/custom) → **Profil**
   (laptop/desktop) → **Identitaet** (user, host, Zeitzone, Locales, Git) →
   **Bundles** (core/terminal/editor/desktop/browser/dev/latex/notes/media/
   gaming/chat/net/fun; shell+greeter immer an) → **Review** → **doppelte
   Bestaetigung** (nichts passiert vorher).
5. Danach: `nixos-generate-config --root /mnt` (Hardware NIE aus dem Repo
   kopiert), dry-build, `nixos-install --root /mnt --flake $REPO#nixos`,
   reboot, als User einloggen, `passwd` setzen, Repo frisch nach
   `~/Projects/dotfiles` klonen, `./scripts/apply.sh`.
6. Verify: `./scripts/verify.sh` (gruen bis auf ggf. Konsolen-Warnungen).

Tastatur gilt fuer Konsole + XKB + Noctalia-Greeter + Umbriel (folgt dem
System-Default; gb-XKB nutzt uk-Konsole). Profil steuert nur Quirks
(intel_vbtn-Blacklist nur laptop) — nie die Hardware-Erkennung.

### Modus 2 — Anwenden auf installiertem NixOS

```bash
cd ~/Projects/dotfiles
./scripts/apply.sh --dry-run   # Vorschau, aendert nichts
./scripts/apply.sh --wizard    # Auswahl neu treffen (TUI), dann anwenden
./scripts/apply.sh             # preflight → symlinks → dry-build → switch → verify
```

Preflight bricht ab bei: kein NixOS (schuetzt Arch-Dev-PC), Live-ISO
(`nixos-rebuild` wuerde nur RAM aendern), root-User, falschem User,
dirty tree, fehlender Hardware-Config (wird validiert adoptiert, nie blind
kopiert). Die Hardware-Config wird nur per `git add -f` gestagt und danach
immer zurueckgesetzt/geloescht — keine UUIDs nach GitHub.

### Modus 3 — Updates (explizit, nie automatisch)

```bash
./scripts/update.sh           # = --check: fetch + zeigen, was remote neu ist
./scripts/update.sh --pull    # nur bei clean tree; danach DIFF reviewen
./scripts/update.sh --inputs  # nix flake update (Pins loesen — bewusst)
./scripts/apply.sh            # erst DAS aktiviert etwas (pro PC getrennt)
```

Lifecycle: installieren → lokaler Checkout ist die Quelle → bewusst pullen →
reviewen → bewusst applyen. `git pull` auf PC A aendert PC B nie. Flake-Inputs
bleiben gepinnt (`flake.lock`), bis `--inputs` laeuft.

### Modus 4 — Verify & Repair

```bash
./scripts/verify.sh   # read-only: symlinks, Binaerprogramme, Secrets, Host-Files
```

Fatale FAILs: fehlende Config-Links, fehlende Hardware-Config, nicht-ignorierte
Host-Files, Secrets im Repo. Warnungen (kein Exit-1): Binaerprogramme/XDG auf
Konsolen-Systemen, fehlende `local.nix`. Recovery nach Fehl-Rebuild: vorherige
Generation im Bootmenue waehlen (30d GC-Schutz), Fehler in `local.nix`/Modulen
fixen, `apply.sh --dry-run`, erneut applyen.

### Dateien & Kategorien

| Kategorie | Wo | Wirkung |
| :--- | :--- | :--- |
| deklarativ | Nix/Home-Manager (`home-entry.nix`) | erst nach rebuild aktiv |
| generiert | `hosts/nixos/local.nix` + `hardware-configuration.nix` (git-ignoriert!) | pro Maschine, Installer-Auswahl |
| deployed | `~/.config`-Symlinks (`*.pre-dotfiles`-Backup, nie ueberschrieben) | explizit via apply.sh |
| lokal | `~/Pictures/Wallpapers`, Secrets, `~/.local/state` | bleibt liegen, nie versioniert |

Auswahl aendern: `apply.sh --wizard` oder `local.nix` editieren → `apply.sh`.
Core-Liste aendern: `home/programs/bundles.nix` (EIN Ort) → committen → pro PC
`update.sh --pull` + `apply.sh`. Theme: Noctalia-Palette Haven
(`background #070e15`, `foreground #e9efeb`, `accent #97a6bb`); generierte
Theme-Dateien (gtk/kitty/rofi) NICHT hand-editieren.
Maschinen-spezifisch (Outputs, Skalierung) gehoert NICHT in geteilte Configs —
lokal ergaenzen, nicht committen.

### Zweit-PC (bestehendes minimal-NixOS → volles Setup)

1. Minimales NixOS 26.05 installieren (kein Desktop, EFI/systemd-boot, User
   anlegen, NetworkManager an), in die Konsole booten.
2. Als User mit Netz: `nix-shell -p git curl` (eine Shell).
3. `REF=<sha> bash <(curl --proto '=https' --tlsv1.2 -fsSL
   https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/$REF/scripts/bootstrap.sh)`
   (bootstrap = Checkout-Helfer fuer INSTALLIERTE Systeme, bricht auf
   Live-ISO/Arch/dirty-tree ab).
4. `apply.sh --wizard` → Auswahl treffen → dry-build → switch → reboot →
   Noctalia-Greeter-Login → `verify.sh`.

Manuell bleiben: Partitionen/User/Netz der Basisinstallation, sudo-Passwort
beim ersten Lauf, externe Binaries (`~/.local/bin/{omp,cliamp-real,
zapfast-real,pakmc-bin}` — Installer warnt), `~/Music`-Inhalte,
Secrets/Logins (GitHub, Bitwarden, WLAN).
<img src="assets/screenshots/noctalia.png" alt="Noctalia control center" width="750">

## Stack

| Layer | Choice |
| :---- | :----- |
| Distro | NixOS 26.05 |
| Compositor | Umbriel |
| Shell | Noctalia (bar, launcher, theming) |
| Terminal | foot (default) / kitty / alacritty / ghostty |
| Prompt | fish + starship |
| Editor | Zed (default) / Neovim |
| Browser | Zen (pinned flake input) |
| Files | Nautilus / Yazi |
| Music | mpd + mpc + rmpc, kew, cliamp |
| Launcher | walker |

<details>
<summary><b>Full app list</b></summary>

| App | Purpose |
| :-- | :------ |
| foot / kitty / alacritty / ghostty | terminals |
| walker | launcher |
| umbriel | compositor |
| noctalia (+ noctalia-greeter) | shell + login screen |
| zed-editor / neovim | editors |
| nautilus / yazi | file managers |
| zen-browser | browser (pinned flake input) |
| mpd + mpc + rmpc, kew, cliamp | music |
| sonora | music player (flake input) |
| toofan | typing test (flake input) |
| mpv, imv | media viewers |
| btop, fastfetch | monitor / info |
| qalculate-qt + libqalculate | calculator |
| wiremix, playerctl, brightnessctl | audio / brightness |
| obsidian, zettlr, readest | notes / reading |
| gh, lazygit, lazydocker | git / docker |
| bitwarden-cli | passwords |
| wireshark, nmap, iw, bluez | network / bluetooth |
| prismlauncher, steam-run, osu-lazer-bin | gaming |
| concord, flare-signal | chat |
| pi-coding-agent, nodejs, python3 | dev runtimes |
| texlive (scheme-small), texlab, zathura | LaTeX toolchain + PDF viewer |
| nix-search-tv, nil, alejandra, nh, jq | nix tooling |
| wl-clipboard, grim, slurp, wlsunset, swaylock, xwayland-satellite, polkit_gnome | wayland helpers |
| eza, fzf, zoxide, bat, fd, ripgrep, tmux, starship, git, tree, unzip, zip, file, wget, psmisc, cava, gdu, ffmpeg, appimage-run, xdg-utils, file-roller, adwaita-icon-theme, yaru-theme, qt6ct, inkscape, lmstudio (buildFromSource only) | cli / utils / assets |

</details>

## Theme

Single source: Noctalia palette **Haven** (`background #070e15`, `foreground #e9efeb`, `accent #97a6bb`). Every app consumes it — umbriel, foot, GTK, Qt, yazi, zed, starship, btop, walker. Generated files are committed as a starting point; Noctalia rewrites them on theme change, which shows up as an intentional `git diff`.

## Layout

```
flake.nix               inputs (pinned in flake.lock) + nixosConfigurations.nixos (lysec = mkDefault settings.nix)
hosts/nixos/            settings.nix (Defaults), default.nix, local.nix(.example) + hardware-configuration.nix(.example) — local+hw gitignoriert
modules/lysec/          options (username, keyboard, profil, locales, bundles, ...)
modules/nixos/          boot/nix/locale/networking/audio/greeter/user (locale+greeter+boot folgen lysec)
desktops/umbriel/       umbriel nixos.nix + home.nix (config folgt System-XKB, keine Outputs im Repo)
desktops/shared/        shared wayland home config
home/programs/          bundles.nix (EIN Ort fuer alle Pakete) + default.nix (resolve + fromSource-Gate)
home/shell/             fish/git/starship/mpd config
home-entry.nix          home-manager entrypoint (identity + symlinks)
configs/dotconfig/      plain app configs → ~/.config (no Nix string escaping)
home/.local/bin/        helper scripts  scripts/  live-installer.sh, install-wizard.sh, apply.sh, update.sh, verify.sh, lib.sh (+ install.sh-Shim, bootstrap.sh)
```

## Notes

- **Hardware config** is host-specific: erzeugt per `nixos-generate-config --root /mnt` (ISO) bzw. validiert adoptiert (apply.sh) — nie aus dem Repo kopiert, nie committen.
- **Live state** (`~/.local/state/noctalia/settings.toml`, wallpapers in `~/Pictures/Wallpapers/`) is not versioned — the tracked copy under `home/.local/state/noctalia/settings.toml` is the starting point.
- **External binaries** (`~/.local/bin/{omp,cliamp-real,zapfast-real,pakmc-bin}`) have no nixpkgs source; the installer warns if missing.
- **Neovim** is stock LazyVim plus a look-only layer (`minimal.lua`: no icons, transparent, square borders, base16-Noctalia via `matugen.lua`), fully tracked under `configs/dotconfig/nvim/` and symlinked to `~/.config/nvim`; LSPs/formatters come from Mason (`stylua`, `shfmt`, `tree-sitter-cli` installed, rest on demand).
- **LaTeX** had no local toolchain — `texlive scheme-small` + `texlab` + `zathura` are now declared (bundle `latex`); untested against a real `.tex` document.
- **Noch manuell/experimentell**: Partitionierung (Anleitung, kein Disko), LUKS-Verschluesselung, WLAN im Installer, `wlsunset`-Koordinaten folgen der Zeitzone nicht automatisch, Noctalia-Settings-Outputs (`eDP-1` etc.) sind Live-State pro Maschine.
