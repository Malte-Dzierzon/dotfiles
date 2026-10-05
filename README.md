<div align="center">

# dotfiles

**NixOS + niri + Noctalia — one flake, one theme source.**

![](https://img.shields.io/github/last-commit/Malte-Dzierzon/dotfiles?&style=flat-square&color=8ad7eb&logo=git&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/NixOS-26.05-5277C3?style=flat-square&logo=nixos&logoColor=D9E0EE&labelColor=1E202B)
[![CI](https://img.shields.io/github/actions/workflow/status/Malte-Dzierzon/dotfiles/ci.yml?style=flat-square&label=CI)](https://github.com/Malte-Dzierzon/dotfiles/actions)

<img src="assets/screenshots/desktop.png" alt="desktop" width="750">

</div>

## Install

```bash
git clone https://github.com/Malte-Dzierzon/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./scripts/install.sh --dry-run   # preview, changes nothing
./scripts/install.sh             # full install + rebuild + verify
```

One-liner for a fresh machine:

```bash
curl -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/main/scripts/bootstrap.sh | bash
```

| Flag | Effect |
| :--- | :----- |
| `--dry-run` | print every action, change nothing |
| `--no-rebuild` | symlinks only, skip `nixos-rebuild` |
| `--no-user-pkgs` | skip `nix profile` installs |
| `--desktop=<name>` | switch compositor (`niri` \| `umbriel` \| `hyprland` \| `mango`) |
| `--verify-only` | run health check, change nothing |

What the installer does: dry-build first (aborts before switching on failure) → links `configs/dotconfig/*` to `~/.config/` (real dirs backed up to `*.pre-dotfiles`) → adopts the host's `hardware-configuration.nix` → `nh os switch` → installs pinned flake inputs → runs `scripts/verify.sh`.

<img src="assets/screenshots/noctalia.png" alt="Noctalia control center" width="750">

## Stack

| Layer | Choice |
| :---- | :----- |
| Distro | NixOS 26.05 |
| Compositor | niri (default) / umbriel |
| Shell | Noctalia (bar, launcher, theming) |
| Terminal | foot (default) / kitty / alacritty / ghostty |
| Prompt | fish + starship |
| Editor | Zed (default) / Neovim |
| Browser | Zen |
| Files | Nautilus / Yazi |
| Music | mpd + rmpc, kew |

## Theme

One source: Noctalia palette **Haven** (`background #070e15`, `foreground #e9efeb`, `accent #97a6bb`). Every app consumes it — niri, foot, GTK, Qt, yazi, zed, starship, btop, walker. Generated files are committed as a starting point; Noctalia rewrites them on theme change, which shows up as an intentional `git diff`.

## Layout

```
flake.nix               inputs (pinned in flake.lock) + nixosConfigurations.nixos
hosts/nixos/            settings.nix, default.nix (+ host hardware-configuration.nix, gitignored)
modules/nixos/          system areas (boot, nix, locale, networking, audio, greeter, user)
desktops/<name>/        per-compositor nixos.nix + home.nix
home/programs/          package list    home/shell/  fish/zsh config
home-entry.nix          home-manager entrypoint (identity + symlinks)
configs/dotconfig/      plain app configs → ~/.config (no Nix string escaping)
home/.local/bin/        helper scripts  scripts/  install.sh, verify.sh, bootstrap.sh
```

## Notes

- **Hardware config** is host-specific: the installer copies it from `/etc/nixos/` on first run, never from the repo.
- **Live state** (`~/.local/state/noctalia/settings.toml`, wallpapers in `~/Pictures/Wallpapers/`) is not versioned.
- **External binaries** (`~/.local/bin/{omp,cliamp-real,zapfast-real,pakmc-bin}`) have no nixpkgs source; the installer warns if missing.
- Switch compositor: `./scripts/install.sh --desktop=umbriel` or edit `desktop` in `hosts/nixos/settings.nix`, then `nh os switch ~/Projects/dotfiles`.
