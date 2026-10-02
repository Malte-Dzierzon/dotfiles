<div align="center">

# dotfiles

**NixOS + niri + Noctalia — one flake, one theme source.**

![](https://img.shields.io/github/last-commit/Malte-Dzierzon/dotfiles?&style=flat-square&color=8ad7eb&logo=git&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/NixOS-26.05-5277C3?style=flat-square&logo=nixos&logoColor=D9E0EE&labelColor=1E202B)

<img src="assets/screenshots/desktop.png" alt="desktop" width="750">

</div>

## Install

```bash
git clone https://github.com/Malte-Dzierzon/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./scripts/install.sh
```

Fresh system, one line:

```bash
curl -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/main/scripts/bootstrap.sh | bash
```

```bash
./scripts/install.sh --no-rebuild --no-user-pkgs   # symlinks only
./scripts/install.sh --desktop=hyprland            # switch compositor + rebuild
```

## What's inside

- **Compositors** — niri (default), hyprland, mango. Switch with one option in `hosts/nixos/settings.nix`, session picker in the greeter (greetd + Noctalia Greeter).
- **One theme source** — Noctalia generates the palette, every app consumes it. Full map in <details>below</details>.
- **Plain configs** — everything editable under `configs/dotconfig/`, linked to `~/.config` by home-manager. No Nix string escaping.
- **mpd + rmpc** as user service, **fish + starship** prompt, **walker** launcher.

<img src="assets/screenshots/noctalia.png" alt="Noctalia control center" width="750">

## Software

| Component | Choice |
| :-------- | :----- |
| Distro | NixOS 26.05 |
| Shell | Noctalia |
| Compositor | niri / hyprland / mango |
| Terminal | foot / kitty / alacritty / ghostty |
| Shell / Prompt | fish / starship |
| Editor | Neovim / Zed |
| Launcher | walker |
| Files | Nautilus / Yazi |
| Music | mpd + rmpc, kew |
| Media / Monitor | mpv, imv / btop, cava, fastfetch |

## Theming

<details>
<summary><b>Palette</b></summary>

| Swatch | Token | Hex |
|---|---|---|
| ![#070e15](https://placehold.co/15x15/070e15/070e15.png) | `background` | `#070e15` |
| ![#e9efeb](https://placehold.co/15x15/e9efeb/e9efeb.png) | `foreground` | `#e9efeb` |
| ![#97a6bb](https://placehold.co/15x15/97a6bb/97a6bb.png) | `accent` / `blue` | `#97a6bb` |
| ![#62676c](https://placehold.co/15x15/62676c/62676c.png) | `muted` | `#62676c` |
| ![#20262c](https://placehold.co/15x15/20262c/20262c.png) | `surface` | `#20262c` |
| ![#857960](https://placehold.co/15x15/857960/857960.png) | `red` | `#857960` |
| ![#82967f](https://placehold.co/15x15/82967f/82967f.png) | `green` | `#82967f` |
| ![#96937b](https://placehold.co/15x15/96937b/96937b.png) | `yellow` | `#96937b` |
| ![#83a2a3](https://placehold.co/15x15/83a2a3/83a2a3.png) | `cyan` | `#83a2a3` |
| ![#6c7b91](https://placehold.co/15x15/6c7b91/6c7b91.png) | `magenta` | `#6c7b91` |

</details>

<details>
<summary><b>Themed apps (22)</b></summary>

| App | Mechanism |
| :-- | :-------- |
| niri | `include "noctalia.kdl"` |
| hyprland | `source = noctalia.conf` |
| foot | `include=…/themes/noctalia` |
| kitty | `include themes/noctalia.conf` + `~/.cache/noctalia/colors-kitty.conf` |
| alacritty | `import = […/noctalia.toml]` |
| btop | `color_theme = "noctalia"` |
| cava | theme file `cava/noctalia` |
| rofi | `@import "noctalia.rasi"` |
| GTK 3/4 | `noctalia.css` |
| Qt5ct/Qt6ct | `colors/noctalia.conf` |
| yazi | `flavor dark/light = "noctalia"` |
| walker | theme dir |
| zed | `themes/noctalia.json` |
| opencode | `themes/noctalia.json` |
| fastfetch | `noctalia.jsonc` |
| starship | embedded `[palettes.noctalia]` |
| nvim | matugen bridge |
| zapfast / PrismLauncher | `*-noctalia-sync` scripts |

Generated files are committed as a starting point — Noctalia rewrites them on theme change, which shows up as an intentional `git diff`.

</details>

<details>
<summary><b>Sync scripts</b></summary>

| Script (`home/.local/bin/`) | Purpose |
| :----- | :------ |
| `zapfast-noctalia-sync` | Regenerates the zapfast theme — hook into Noctalia Settings → Hooks → `colorGeneration` |
| `prism-noctalia-sync` | Syncs the palette into the PrismLauncher theme |

</details>

## Layout

<details>
<summary><b>Repository structure</b></summary>

```
flake.nix                 # inputs + nixosConfigurations.nixos
hosts/nixos/              # settings.nix, configuration.nix, default.nix
modules/lysec/            # shared lysec.* options
modules/nixos/            # system modules (boot, nix, locale, networking, audio, greeter, user)
desktops/<name>/          # per-compositor nixos.nix + home.nix
desktops/shared/          # shared Wayland defaults
home/                     # programs index, shell, mpd service
home-entry.nix            # home-manager entrypoint (identity + symlinks + desktop profile)
configs/dotconfig/        # plain app configs -> ~/.config
home/.local/bin/          # helper scripts (on PATH)
home/.local/share/applications/  # .desktop entries
scripts/                  # install.sh, bootstrap.sh
assets/screenshots/       # README images
```

| Task | File |
| :--- | :--- |
| Switch compositor | `hosts/nixos/settings.nix` (`desktop`), then `nh os switch ~/Projects/dotfiles` |
| System area | `modules/nixos/<area>.nix` |
| Compositor Nix/home | `desktops/<name>/{nixos,home}.nix` |
| App config | `configs/dotconfig/<app>/` |
| Packages | `home/programs/default.nix` |

</details>

## FAQ

<details>
<summary>How do I switch compositors?</summary>

Set `desktop` in `hosts/nixos/settings.nix` (`niri` | `hyprland` | `mango`), then `nh os switch ~/Projects/dotfiles` — or `./scripts/install.sh --desktop=mango` in one step.

</details>

<details>
<summary>Where are my configs applied from?</summary>

`configs/dotconfig/<app>/` is symlinked to `~/.config/<app>/` (by home-manager after rebuild, by `install.sh` immediately as fallback). Edit in the repo, changes apply instantly — except Nix-managed parts (packages, services) which need a rebuild.

</details>

<details>
<summary>Why do themed files show as modified after a wallpaper change?</summary>

Noctalia regenerates its theme files in place. That's intentional — review the diff, keep it or revert it.

</details>
