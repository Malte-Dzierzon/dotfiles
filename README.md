<div align="center">

# dotfiles

**NixOS + niri + Noctalia — one flake, one theme source.**

![](https://img.shields.io/github/last-commit/Malte-Dzierzon/dotfiles?&style=flat-square&color=8ad7eb&logo=git&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/NixOS-26.05-5277C3?style=flat-square&logo=nixos&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/niri-compositor-D55C44?style=flat-square&logo=wayland&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/Noctalia-shell-0e0e43?style=flat-square&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/Zed-editor-084D93?style=flat-square&logo=zed&logoColor=D9E0EE&labelColor=1E202B)

<img src="assets/screenshots/desktop.png" alt="desktop" width="750">

</div>

## Install

```bash
git clone https://github.com/Malte-Dzierzon/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./scripts/install.sh --dry-run   # preview, changes nothing
./scripts/install.sh             # full install + rebuild + verify
```

Fresh machine one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/main/scripts/bootstrap.sh | bash
```

| Flag | Effect |
| :--- | :----- |
| `--dry-run` | print every action, change nothing |
| `--no-rebuild` | symlinks only, skip `nixos-rebuild` |
| `--no-user-pkgs` | skip external binaries |
| `--desktop=<name>` | switch compositor (`niri` \| `umbriel`) |
| `--verify-only` | run health check, change nothing |

The installer dry-builds first (aborts before switching on failure), links `configs/dotconfig/*` to `~/.config/` (existing files backed up to `*.pre-dotfiles`), adopts the host's `hardware-configuration.nix`, runs `nh os switch`, and finishes with `scripts/verify.sh`.

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
| Browser | Zen (pinned flake input) |
| Files | Nautilus / Yazi |
| Music | mpd + rmpc, kew, cliamp |

<details>
<summary><b>Full app list</b></summary>

| App | Purpose |
| :-- | :------ |
| foot / kitty / alacritty / ghostty | terminals |
| walker | launcher |
| zed-editor / neovim | editors |
| nautilus / yazi | file managers |
| zen-browser | browser (pinned flake input) |
| noctalia | shell: bar, launcher, theming |
| mpd + mpc + rmpc, kew, cliamp | music |
| mpv, imv | media viewers |
| btop, fastfetch | monitor / info |
| qalculate | calculator (`qalc`, Noctalia launcher) |
| wiremix | audio mixer (TUI) |
| obsidian, zettlr, readest | notes / reading |
| gh, lazygit, lazydocker | git / docker |
| bitwarden-cli | passwords |
| wireshark, nmap | network |
| prismlauncher, steam-run, osu-lazer-bin | gaming |
| concord, flare-signal | chat |
| pi-coding-agent, nodejs | dev runtimes |
| wl-clipboard, grim, slurp, wlsunset | wayland helpers |
| eza, fzf, zoxide, bat, fd, ripgrep | cli essentials |

</details>

## Theme

Single source: Noctalia palette **Haven** (`background #070e15`, `foreground #e9efeb`, `accent #97a6bb`). Every app consumes it — niri, foot, GTK, Qt, yazi, zed, starship, btop, walker. Generated files are committed as a starting point; Noctalia rewrites them on theme change, which shows up as an intentional `git diff`.

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
