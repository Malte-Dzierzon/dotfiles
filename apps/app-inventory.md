# App-Inventory — tatsächlich verwendete Benutzer-Apps

Stand: 2026-10-14, verifiziert am laufenden NixOS-System (`/etc/profiles/per-user/xealom/bin`, 392 Binaries) + altem Katalog (`main:nix/home/programs/bundles.nix`) + Flatpak + `~/.config`. Status: **installiert** = Binary vorhanden · **Katalog** = nur im Nix-Katalog vorgesehen · **nicht verifiziert** = weder Binary noch Beleg.

Systemabhängigkeiten (Kernel, libc, PipeWire-Dienste, Mesa, Polkit, BlueZ-Daemons …) stehen bewusst NICHT hier, sondern in `system/packages.md` und `system/services/services.md`.

## GUI-Apps

| App | Zweck | Jetzt | openSUSE-Weg | Update | Config |
|---|---|---|---|---|---|
| Zen Browser (`zen`) | Standardbrowser | installiert (Flake-Input) | Upstream-Tarball | manuell/Upstream | nicht gesichert (Profil) → manuell exportieren |
| Nautilus | Dateimanager (Standard) | installiert | nativ | zypper | keine eigene Config |
| Zed (`zeditor`) | GUI-Editor (Standard) | installiert | Upstream-Script | Upstream-Script | gesichert → `configs/development/zed` |
| Obsidian (+cli) | Notizen (Standard) | installiert | Flatpak | flatpak | nicht verifiziert → Vault manuell |
| Flare (`flare`) | Signal-Client | installiert (pkgs flare-signal) | Flatpak/nativ prüfen | zypper/flatpak | nicht konfiguriert (Session) |
| Concord (`concord`) | Discord-Client | installiert (Flake-Input) | Upstream-Release | manuell | nicht konfiguriert (Session) |
| Readest (`readest`) | E-Book/PDF-Reader | installiert | Flatpak prüfen | flatpak | nicht konfiguriert |
| Zathura | PDF-Reader (Standard) | installiert | nativ | zypper | nicht konfiguriert |
| mpv / imv / chafa | Medienbetrachter | installiert | nativ | zypper | keine eigene Config |
| qalculate-qt | Rechner | installiert | nativ | zypper | keine eigene Config |
| file-roller | Archivmanager | installiert | nativ | zypper | — |
| Serein (Flatpak `cz.viceverse.serein`) | Flatpak-Service-App | installiert (flatpak user) | Flatpak | flatpak | nicht konfiguriert |
| Walker / roti? (`walker`, rofi-Config vorhanden) | Launcher | installiert | nativ/cargo | zypper | gesichert → `configs/desktop/walker`, `rofi` |
| grim + slurp | Screenshots | installiert | nativ | zypper | keine eigene Config |
| swaylock | Lockscreen | installiert | nativ | zypper | gesichert → `configs/desktop/swaylock` |
| wlsunset / brightnessctl | Nachtmodus/Helligkeit | installiert | nativ | zypper | keine eigene Config |
| wiremix / playerctl | Audio-/Mediensteuerung | installiert | nativ | zypper | keine eigene Config |
| xwayland-satellite | XWayland-Compat | installiert | nativ | zypper | — |
| Umbriel + Noctalia (+greeter) | Compositor/Shell/Greeter | installiert (Flake-Inputs) | Upstream-Quelle | manuell | gesichert → `configs/desktop/umbriel`, `noctalia` |
| Ghostty | Terminal (extra) | Katalog? nein — **Config vorhanden, Binary fehlt** | nativ prüfen | zypper | gesichert → `configs/shell/ghostty` |
| Epiphany/Evolution/Zettlr | — | nicht verifiziert (nur alte `~/.config`-Reste) | — | — | veraltet, ignorieren |

## TUI-Apps

| App | Zweck | Jetzt | openSUSE-Weg | Config |
|---|---|---|---|---|
| Yazi | Filemanager-TUI | installiert | nativ/cargo | gesichert → `configs/development/yazi` |
| Lazygit / Lazydocker | Git/Docker-TUI | installiert | nativ (lazydocker) / Upstream | lazygit gesichert; lazydocker keine Config |
| btop / fastfetch | Monitor/Fetch | installiert | nativ | gesichert → `configs/shell/btop`, `fastfetch` |
| cava | Audio-Visualizer | installiert | nativ | gesichert → `configs/shell/cava` |
| mpd + mpc + rmpc / kew / cliamp / sonora? | Musikplayer | mpd/mpc/rmpc/kew/cliamp/toofan installiert; **sonora nur Katalog, Binary fehlt** | nativ | mpd/cliamp/kew/rmpc/toofan gesichert; sonora-Config vorhanden (`configs/desktop/sonora`) aber App fehlt → auf openSUSE prüfen |
| toofan | Audio-Tool (Flake) | installiert | Upstream-Release | gesichert |

## CLI- und Shell-Tools

| App | Jetzt | openSUSE-Weg | Config |
|---|---|---|---|
| fish (+ zsh, starship, tmux, foot default, kitty, alacritty) | installiert | nativ | gesichert → `configs/shell/*` (zsh nur `zshrc-backup`) |
| git + gh + direnv + nix-search-tv | installiert | nativ | git-Identität war Nix-Modul → manuell setzen |
| fzf, eza, zoxide, bat, fd, ripgrep, tree, jq, gdu, chafa, unzip, file, wget, psmisc | installiert | nativ | keine eigene Config |
| neovim (LazyVim) + gcc (Tree-sitter) | installiert | nativ | gesichert → `configs/development/nvim` |
| texlive scheme-small + texlab | installiert (tex-Binaries vorhanden) | nativ (texlive) | keine eigene Config |
| ffmpeg (ffplay/ffprobe), imv, appimage-run, xdg-utils? | ffmpeg/appimage-run installiert; **xdg-utils Binary fehlt** | nativ | — |
| bitwarden-cli (`bw`) | installiert | nativ/npm prüfen | nicht konfiguriert (Vault) |
| nil + alejandra + nh | installiert (Nix-Tooling) | **entfällt auf openSUSE** | — |
| docker, tailscale, iw, nmap | installiert (Systemdienst/nativ) | nativ | Dienste s. `system/services/` |
| node/python3/bun (`bun` via nix-profile) | installiert | nativ (node/python) + Upstream (bun) | — |
| Eigene Skripte: `default-app` (portiert, 6 Rollen), `prism` (portiert) | portiert in `system/scripts/` | direkt nutzbar | gesichert, getestet (`--list` ok) |
| Historische Referenzen (NICHT portabel): filius, pakmc, slipper, zapfast, omp-mic, qalculate-qt-themed, prism-noctalia-sync | nur `system/scripts/reference/` | ersetzen s. Tabelle dort | Doku, nicht ausführbar |

## KI- und Coding-Agents (Upstream-first, nie Distro-Pakete)

| App | Jetzt | openSUSE-Weg | Update | Config |
|---|---|---|---|---|
| omp (Oh My Pi) | installiert (Flake-Input) | `npm i -g oh-my-pi` | npm | gesichert → `configs/ai/omp` |
| pi-coding-agent (`pi`) | installiert (pkgs) | `npm i -g pi-coding-agent` | npm | gesichert → `configs/ai/pi-agent` |
| opencode | installiert (pkgs) | offizielles Install-Script | `opencode upgrade` | nur Ref (`package.json`), Binär-DB ausgeschlossen |
| lms (LM-Studio-CLI) | installiert | offizieller Installer | Upstream | Modelle/Daten ausgeschlossen |
| **Oh My SSH**: nichts gefunden (Repo + `$HOME` + PATH durchsucht) | — | — | — | nicht erfunden |

## Gaming

| App | Jetzt | openSUSE-Weg | Config |
|---|---|---|---|
| Prism Launcher | installiert | Flatpak | cfg + Instanzliste gesichert → `configs/gaming/prism` (JavaPath anpassen); Spieldaten excluded |
| osu! (`osu!`-Binary) | installiert (`osu-lazer-bin`) | AppImage/Upstream | nur `framework.ini`-Ref; Realm-DB nicht portabel → Login manuell |
| steam-run (Wrapper) | installiert; **nativer Steam-Client nicht verifiziert** | nativ `steam` | Proton/GameMode/MangoHud auf openSUSE neu einrichten (nicht installiert gewesen) |
| temurin-bin (Java f. Filius) | Katalog, Binary fehlt (`java` = anderes JDK) | nativ temurin prüfen | — |

## Kreativsoftware

| App | Jetzt | openSUSE-Weg | Config |
|---|---|---|---|
| Blender (+thumbnailer) | installiert | nativ | `userpref/startup.blend` gesichert |
| Krita (+runner) | installiert | nativ | `kritarc` gesichert; Ressourcen-Cache excluded |
| Inkscape | installiert | nativ | `preferences.xml` + keys/palettes/templates gesichert |
| Godot 4.7 | installiert | nativ | Editor-Settings + Themes/Templates gesichert |

## Spezialsoftware / Hardware-Tools

| App | Jetzt | openSUSE-Weg | Config |
|---|---|---|---|
| OpenTabletDriver (`otd`-Daemon) | installiert (Systemdienst) | Upstream-RPM | XP-Pen-Profil + udev-Regel gesichert |
| HeadsetControl | installiert (Systemdienst) | nativ/Upstream | udev-Regeln gesichert (`system/hardware/`) |
| Noctalia-Greeter-Tools | installiert | mit Noctalia | s. Desktop |

## Neu entdeckt vs. entfallen (Abgleich Branch ↔ System ↔ alter Katalog)

- Neu ins Inventar aufgenommen (liefen unter dem Radar): `bw`, `lms`, `toofan`-Herkunft geklärt, `concord`/`flare` Klarnamen, `steam-run`-vs-Steam, `zeditor`-Binary, TeXLive-Tatsächlichkeit, Flatpak-Serein.
- Fehlend trotz Config (auf openSUSE nachinstallieren oder streichen): Ghostty, Sonora.
- Katalog-Leichen (weder Binary noch Config-Nutzen): `xdg-utils`-Binary, `temurin-bin`, `linux-wifi-hotspot`, `bitwarden`? (nein — `bw` existiert), Ghostty-Build.
- Entfällt auf openSUSE ersatzlos: nil, alejandra, nh, nix-search-tv (Nix-Tooling).
- Eigene Skripte (`filius`, `pakmc`, `slipper`, `zapfast`, `default-app` …) sind repo-only und landen in `system/scripts/` — kein PATH-Install nötig.
