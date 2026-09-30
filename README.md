# dotfiles

NixOS flake with home-manager, three Wayland compositors (niri default, hyprland, mango) and Noctalia shell. Structure follows Ly-sec/nixos, config layout follows Noctara-Dots.

## Table of Contents

- [Overview](#overview)
- [Why this setup](#why-this-setup)
- [Software Used](#software-used)
- [Quick Start](#quick-start)
- [Switching Desktops](#switching-desktops)
- [Repository Structure](#repository-structure)
- [Configuration](#configuration)
- [Credits](#credits)

## Overview

One host, one flake, declarative from bootloader to keybinds. The active compositor is a single option in `hosts/nixos/settings.nix`; only that desktop's modules are imported at build time. User configs live as plain files under `configs/` and are linked into `~/.config` by home-manager.

Login runs through greetd + Noctalia Greeter with a session picker (niri / hyprland / mango).

## Why this setup

- Single switch: change `desktop` in one file, rebuild, done.
- Modular: each system area is its own module under `modules/nixos/`, each compositor its own folder under `desktops/`.
- Plain configs: niri/hypr/mango/noctalia stay editable KDL/conf files, no Nix string escaping.
- One-command install: `scripts/install.sh` handles nix, symlinks, rebuild and user packages.

## Software Used

| Component          | Software              |
| :----------------- | :-------------------- |
| Distro             | NixOS 26.05           |
| Desktop Shell      | Noctalia              |
| Window Manager     | niri / hyprland / mango |
| Greeter            | Noctalia Greeter (greetd) |
| Terminal           | foot                  |
| Shell              | fish                  |
| Prompt             | starship              |
| Editor             | Neovim / Zed          |
| Launcher           | walker                |
| File Manager       | Nautilus / Yazi       |
| System Info        | fastfetch             |
| Music              | kew                   |
| Media Player       | mpv / imv             |

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

This does: check nix + flakes -> optional hardware-configuration takeover -> link `configs/` to `~/.config` -> `nh os switch` (fallback `nixos-rebuild`) -> per-user packages (zen-browser).

### Options

```bash
./scripts/install.sh --no-rebuild --no-user-pkgs   # symlinks only
./scripts/install.sh --desktop=hyprland            # switch compositor + rebuild
```

## Switching Desktops

Edit `hosts/nixos/settings.nix`:

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
  flake.nix                 # inputs + nixosConfigurations.nixos
  hosts/nixos/              # settings.nix, configuration.nix, default.nix (entrypoint)
  modules/lysec/            # shared lysec.* options
  modules/nixos/            # system modules (boot, nix, locale, networking, audio, greeter, user)
  desktops/<name>/          # per-compositor nixos.nix + home.nix (niri, hyprland, mango)
  desktops/shared/          # shared Wayland defaults
  home/                     # shared home-manager (programs index, shell)
  home-entry.nix            # home-manager entrypoint (identity + symlinks + desktop profile)
  configs/                  # plain dotfiles, linked to ~/.config
    dotconfig/{niri,hypr,mango,noctalia,fish}/
  home/.local/{bin,share/applications}/
  overlays/                 # package overlays
  scripts/                  # install.sh, bootstrap.sh
  assets/                   # screenshots
  Pictures/Wallpapers/      # wallpapers
```

## Configuration

| Task | File |
| :--- | :--- |
| Switch compositor | `hosts/nixos/settings.nix` (`desktop`) |
| System module | `modules/nixos/<area>.nix` |
| Compositor Nix side | `desktops/<name>/nixos.nix` |
| Compositor home side | `desktops/<name>/home.nix` |
| Compositor config | `configs/dotconfig/<name>/` |
| User packages | `home/programs/default.nix` |
| Shell | `home/shell/default.nix`, `configs/dotconfig/fish/` |

Keybinds and rules stay in the compositor configs (`configs/dotconfig/niri/config.kdl`, `configs/dotconfig/hypr/`, `configs/dotconfig/mango/`), themed through Noctalia.

## Credits

- [Ly-sec/nixos](https://github.com/Ly-sec/nixos) for the flake layout (hosts + modules + desktops + settings switch)
- [Noctara-Dots](https://github.com/deadduck-09/Noctara-Dots) for the config layout and README structure
- [Niri](https://github.com/YaLTeR/niri)
- [Noctalia](https://github.com/NoctaliaDev/noctalia-shell)
- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) for the original scaffold
