# dotfiles

NixOS flake with home-manager, three Wayland compositors (niri default, hyprland, mango) and Noctalia shell as the single theming authority. Structure follows [Ly-sec/nixos](https://github.com/Ly-sec/nixos), config layout follows [Noctara-Dots](https://github.com/deadduck-09/Noctara-Dots).

![Desktop overview](assets/screenshots/desktop.png)
*Placeholder — replace with a screenshot of the running setup.*

## Table of Contents

- [Overview](#overview)
- [Why this setup](#why-this-setup)
- [Features](#features)
- [Software Used](#software-used)
- [Theming](#theming)
- [Quick Start](#quick-start)
- [Switching Desktops](#switching-desktops)
- [Repository Structure](#repository-structure)
- [Configuration](#configuration)
- [Scripts](#scripts)
- [Screenshots](#screenshots)
- [Roadmap](#roadmap)
- [Credits](#credits)

## Overview

One host, one flake, declarative from bootloader to keybinds. The active compositor is a single option in [`hosts/nixos/settings.nix`](hosts/nixos/settings.nix); only that desktop's modules are imported at build time. User configs live as plain files under [`configs/`](configs/) and are linked into `~/.config` by home-manager.

Login runs through greetd + Noctalia Greeter with a session picker (niri / hyprland / mango).

![Launcher](assets/screenshots/launcher.png)
*Placeholder — walker with Noctalia theme.*

## Why this setup

- Single switch: change `desktop` in one file, rebuild, done.
- Modular: each system area is its own module under `modules/nixos/`, each compositor its own folder under `desktops/`.
- Plain configs: niri/hypr/mango/noctalia stay editable KDL/conf files, no Nix string escaping.
- One theme source: Noctalia generates the palette once, every app consumes it — see [Theming](#theming).
- One-command install: [`scripts/install.sh`](scripts/install.sh) handles nix, symlinks, rebuild and user packages.

## Features

- 🖥️ **Three compositors, one switch** — niri (daily driver), hyprland, mango; session picker in the greeter.
- 🎨 **System-wide Noctalia theming** — terminals, GTK, Qt, shell prompt, launcher, music stack all follow the wallpaper palette automatically.
- ⌨️ **Declarative keybinds** — per-compositor, plain config files, versioned in git.
- 🎵 **mpd + rmpc** as user service with themed client.
- 📦 **Reproducible packages** — system and user packages pinned in the flake, no `nix profile install` drift.
- 🚀 **Bootstrap-ready** — fresh NixOS to working desktop with one command.

![Themed terminal](assets/screenshots/terminal.png)
*Placeholder — foot/kitty with generated Noctalia colors.*

## Software Used

| Component      | Software                    |
| :------------- | :-------------------------- |
| Distro         | NixOS 26.05                 |
| Desktop Shell  | Noctalia                    |
| Window Manager | niri / hyprland / mango     |
| Greeter        | Noctalia Greeter (greetd)    |
| Terminal       | foot / kitty / alacritty / ghostty |
| Shell          | fish                        |
| Prompt         | starship (Noctalia palette) |
| Editor         | Neovim / Zed                |
| Launcher       | walker                      |
| File Manager   | Nautilus / Yazi             |
| System Info    | fastfetch                   |
| System Monitor | btop                        |
| Visualizer     | cava                        |
| Music          | mpd + rmpc, kew             |
| Media Player   | mpv / imv                   |

## Theming

Noctalia is the single source of truth. When the wallpaper or colorscheme changes, Noctalia regenerates the palette and every app picks it up through its own include/import — no manual re-theming.

| App | Mechanism | File |
| :-- | :-------- | :--- |
| niri | `include "noctalia.kdl"` | `configs/dotconfig/niri/config.kdl` |
| hyprland | `source = noctalia.conf` | `configs/dotconfig/hypr/noctalia.conf` |
| foot | `include=…/themes/noctalia` | `configs/dotconfig/foot/foot.ini` |
| kitty | `include themes/noctalia.conf` + generated `~/.cache/noctalia/colors-kitty.conf` | `configs/dotconfig/kitty/kitty.conf` |
| alacritty | `import = […/noctalia.toml]` | `configs/dotconfig/alacritty/alacritty.toml` |
| btop | `color_theme = "noctalia"` | `configs/dotconfig/btop/btop.conf` |
| cava | theme file | `configs/dotconfig/cava/noctalia` |
| rofi | `@import "noctalia.rasi"` | `configs/dotconfig/rofi/noctalia.rasi` |
| GTK 3/4 | `noctalia.css` | `configs/dotconfig/gtk-{3,4}.0/` |
| Qt5ct/Qt6ct | `colors/noctalia.conf` | `configs/dotconfig/qt{5,6}ct/` |
| yazi | `flavor dark/light = "noctalia"` | `configs/dotconfig/yazi/theme.toml` |
| walker | theme dir | `configs/dotconfig/walker/themes/noctalia` |
| zed | theme | `configs/dotconfig/zed/themes/noctalia.json` |
| opencode | theme | `configs/dotconfig/opencode/themes/noctalia.json` |
| fastfetch | `noctalia.jsonc` | `configs/dotconfig/fastfetch/` |
| starship | embedded `[palettes.noctalia]` block (regenerated in place) | `configs/dotconfig/starship/starship.toml` |
| nvim | matugen bridge | `configs/dotconfig/nvim/lua/matugen.lua` |
| zapfast / PrismLauncher | generated via sync scripts on palette change | `home/.local/bin/*-noctalia-sync` |

> **Note:** Generated files are committed as a starting point. After a theme change on a live system, Noctalia rewrites them — that shows up as a `git diff`, which is intentional: review it, keep it or revert it.

![Noctalia settings](assets/screenshots/noctalia.png)
*Placeholder — Noctalia shell with matching wallpaper.*

## Quick Start

### Requirements

- A NixOS installation (26.05)
- Internet connection
- `git` (bootstrap pulls it via nix-shell if missing)

### Automatic Installation (Recommended)

Clone and run the installer:

```bash
git clone https://github.com/Malte-Dzierzon/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./scripts/install.sh
```

One-liner for fresh systems:

```bash
curl -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/main/scripts/bootstrap.sh | bash
```

This does: check nix + flakes → optional hardware-configuration takeover → link `configs/` to `~/.config` → `nh os switch` (fallback `nixos-rebuild`) → per-user packages (zen-browser).

### Options

```bash
./scripts/install.sh --no-rebuild --no-user-pkgs   # symlinks only
./scripts/install.sh --desktop=hyprland            # switch compositor + rebuild
```

## Switching Desktops

Edit [`hosts/nixos/settings.nix`](hosts/nixos/settings.nix):

```nix
desktop = "niri"; # niri | hyprland | mango
```

then rebuild:

```bash
nh os switch ~/Projects/dotfiles
```

or in one step: `./scripts/install.sh --desktop=mango`.

## Repository Structure

```
dotfiles/
├── flake.nix                 # inputs + nixosConfigurations.nixos
├── hosts/nixos/              # settings.nix, configuration.nix, default.nix (entrypoint)
│   └── hardware-configuration.nix.example  # copy to hardware-configuration.nix (gitignored)
├── modules/lysec/            # shared lysec.* options
├── modules/nixos/            # system modules (boot, nix, locale, networking, audio, greeter, user)
├── desktops/<name>/          # per-compositor nixos.nix + home.nix (niri, hyprland, mango)
├── desktops/shared/          # shared Wayland defaults
├── home/                     # shared home-manager (programs index, shell)
├── home-entry.nix            # home-manager entrypoint (identity + symlinks + desktop profile)
├── configs/                  # plain dotfiles, linked to ~/.config
│   └── dotconfig/            # foot, kitty, alacritty, ghostty, btop, cava, rofi,
│                             # gtk-3.0/4.0, qt5ct/6ct, yazi, walker, zed, opencode,
│                             # fastfetch, mpv, tmux, rmpc, mpd, nvim, lazygit,
│                             # starship, niri, hypr, mango, noctalia, fish
├── home/.local/{bin,share/applications}/  # helper scripts + .desktop entries
├── scripts/                  # install.sh, bootstrap.sh
├── assets/screenshots/       # README screenshots (placeholders until filled)
└── Pictures/Wallpapers/      # wallpapers (optional, not required for rebuild)
```

## Configuration

| Task | File |
| :--- | :--- |
| Switch compositor | `hosts/nixos/settings.nix` (`desktop`) |
| System module | `modules/nixos/<area>.nix` |
| Compositor Nix side | `desktops/<name>/nixos.nix` |
| Compositor home side | `desktops/<name>/home.nix` |
| Compositor config | `configs/dotconfig/<name>/` |
| App config + theme link | `configs/dotconfig/<app>/` |
| User packages | `home/programs/default.nix` |
| Shell + mpd service | `home/shell/default.nix`, `configs/dotconfig/fish/` |

Keybinds and rules stay in the compositor configs (`configs/dotconfig/niri/config.kdl`, `configs/dotconfig/hypr/`, `configs/dotconfig/mango/`), themed through Noctalia.

## Scripts

Helper scripts in [`home/.local/bin/`](home/.local/bin/) (on `PATH` after install):

| Script | Purpose |
| :----- | :------ |
| `zapfast-noctalia-sync` | Regenerates the zapfast theme from Noctalia colors — hook into Noctalia Settings → Hooks → `colorGeneration` |
| `prism-noctalia-sync` | Syncs the Noctalia palette into the PrismLauncher theme |
| `omp-mic`, `cliamp`, `slipper`, `zapfast`, `elephant`, `zen-browser` | App launchers / wrappers |

## Screenshots

All images live in `assets/screenshots/`. To add one: drop the PNG in, no README change needed beyond the `<img>` line.

- `desktop.png` — full desktop with wallpaper + Noctalia bar (placeholder)
- `launcher.png` — walker with Noctalia theme (placeholder)
- `terminal.png` — foot/kitty with generated colors (placeholder)
- `noctalia.png` — Noctalia settings/overview (placeholder)

## Roadmap

Open ideas — pick one up, delete what doesn't fit:

- [ ] Fill `assets/screenshots/` with real screenshots
- [ ] agenix/secrets module (only when real secrets need versioning)
- [ ] Additional compositor profiles (sway/labwc stubs exist upstream)
- [ ] CI check (`nix flake check` on push)
- [ ] Split `hosts/nixos/configuration.nix` remainder into `modules/nixos/`

## Credits

- [Ly-sec/nixos](https://github.com/Ly-sec/nixos) for the flake layout (hosts + modules + desktops + settings switch)
- [Noctara-Dots](https://github.com/deadduck-09/Noctara-Dots) for the config layout and README structure
- [Niri](https://github.com/YaLTeR/niri)
- [Noctalia](https://github.com/NoctaliaDev/noctalia-shell)
- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) for the original scaffold
