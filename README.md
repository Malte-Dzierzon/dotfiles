<div align="center">
    <h1>【 xealom's NixOS dotfiles 】</h1>
    <h3>niri + Noctalia • one flake, one theme source</h3>
</div>

<div align="center">

![](https://img.shields.io/github/last-commit/Malte-Dzierzon/dotfiles?&style=for-the-badge&color=8ad7eb&logo=git&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/NixOS-26.05-5277C3?style=for-the-badge&logo=nixos&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/niri-wayland-86dbd7?style=for-the-badge&labelColor=1E202B)

</div>

<div align="center">
    <h2>• overview •</h2>
    <h3></h3>
</div>

NixOS flake with home-manager, three Wayland compositors (niri default, hyprland, mango) and Noctalia shell as the single theming authority. Structure follows [Ly-sec/nixos](https://github.com/Ly-sec/nixos), config layout follows [Noctara-Dots](https://github.com/deadduck-09/Noctara-Dots).

<details>
  <summary>What this is/isn't</summary>

- Technically, a full NixOS system config: bootloader to keybinds, one host
- Realistically, mostly plain app configs + one theme pipeline (Noctalia generates, every app consumes)
- NOT a multi-host setup: single `nixos` host, hardware config stays local and gitignored
- NOT a secret store: no agenix/vault until real secrets need versioning

</details>

<details>
  <summary>Notable features</summary>

- **One switch**: change `desktop` in `hosts/nixos/settings.nix`, rebuild, done
- **System-wide theming**: terminals, GTK, Qt, prompt, launcher, music stack all follow the wallpaper palette automatically
- **Plain configs**: niri/hypr/mango/noctalia stay editable KDL/conf files, no Nix string escaping
- **mpd + rmpc** as user service with themed client
- **One-command install**: `scripts/install.sh` handles nix, symlinks, rebuild and user packages

</details>

<details>
  <summary>Installation</summary>

- Clone and run the installer:
  ```bash
  git clone https://github.com/Malte-Dzierzon/dotfiles.git ~/Projects/dotfiles
  cd ~/Projects/dotfiles
  ./scripts/install.sh
  ```
- One-liner for fresh systems:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/main/scripts/bootstrap.sh | bash
  ```
- Options:
  ```bash
  ./scripts/install.sh --no-rebuild --no-user-pkgs   # symlinks only
  ./scripts/install.sh --desktop=hyprland            # switch compositor + rebuild
  ```
- Requirements: NixOS 26.05, internet, `git` (bootstrap pulls it via nix-shell if missing)

</details>

<details>
  <summary>Software overview</summary>

| Software | Purpose |
| :------- | :------ |
| [niri](https://github.com/YaLTeR/niri) / hyprland / mango | Compositors (niri = daily driver) |
| [Noctalia](https://github.com/NoctaliaDev/noctalia-shell) | Desktop shell + single theming authority |
| Noctalia Greeter (greetd) | Login with session picker |
| foot / kitty / alacritty / ghostty | Terminals, all Noctalia-themed |
| fish + starship | Shell + prompt (Noctalia palette) |
| Neovim / Zed | Editors |
| walker | Launcher |
| Nautilus / Yazi | File managers |
| mpd + rmpc, kew | Music stack |
| mpv / imv, btop, cava, fastfetch | Media, monitor, visualizer, sysinfo |

</details>

<div align="center">
    <h2>• screenshots •</h2>
    <h3></h3>
</div>

> Screenshots live in `assets/screenshots/`. Drop a PNG in, no README change needed.

| Desktop | Launcher |
|:---|:---------------|
| <img src="assets/screenshots/desktop.png" alt="desktop placeholder" /> | <img src="assets/screenshots/launcher.png" alt="launcher placeholder" /> |
| Terminal | Noctalia |
| <img src="assets/screenshots/terminal.png" alt="terminal placeholder" /> | <img src="assets/screenshots/noctalia.png" alt="noctalia placeholder" /> |

<div align="center">
    <h2>• theming •</h2>
    <h3></h3>
</div>

Noctalia is the single source of truth. When the wallpaper or colorscheme changes, Noctalia regenerates the palette and every app picks it up through its own include/import — no manual re-theming.

<details>
  <summary>Per-app theme links</summary>

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

</details>

> **Note:** Generated files are committed as a starting point. After a theme change on a live system, Noctalia rewrites them — that shows up as a `git diff`, which is intentional: review it, keep it or revert it.

<div align="center">
    <h2>• structure •</h2>
    <h3></h3>
</div>

<details>
  <summary>Repository layout</summary>

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
├── assets/screenshots/       # README screenshots
└── Pictures/Wallpapers/      # wallpapers (optional, not required for rebuild)
```

</details>

<details>
  <summary>Configuration map</summary>

| Task | File |
| :--- | :--- |
| Switch compositor | `hosts/nixos/settings.nix` (`desktop = "niri"`; niri \| hyprland \| mango), then `nh os switch ~/Projects/dotfiles` |
| System module | `modules/nixos/<area>.nix` |
| Compositor Nix side | `desktops/<name>/nixos.nix` |
| Compositor home side | `desktops/<name>/home.nix` |
| Compositor config | `configs/dotconfig/<name>/` |
| App config + theme link | `configs/dotconfig/<app>/` |
| User packages | `home/programs/default.nix` |
| Shell + mpd service | `home/shell/default.nix`, `configs/dotconfig/fish/` |

Keybinds and rules stay in the compositor configs (`configs/dotconfig/niri/config.kdl`, `configs/dotconfig/hypr/`, `configs/dotconfig/mango/`), themed through Noctalia.

</details>

<details>
  <summary>Helper scripts</summary>

Scripts in [`home/.local/bin/`](home/.local/bin/) (on `PATH` after install):

| Script | Purpose |
| :----- | :------ |
| `zapfast-noctalia-sync` | Regenerates the zapfast theme from Noctalia colors — hook into Noctalia Settings → Hooks → `colorGeneration` |
| `prism-noctalia-sync` | Syncs the Noctalia palette into the PrismLauncher theme |
| `omp-mic`, `cliamp`, `slipper`, `zapfast`, `elephant`, `zen-browser` | App launchers / wrappers |

</details>

<div align="center">
    <h2>• roadmap •</h2>
    <h3></h3>
</div>

- [ ] Fill `assets/screenshots/` with real screenshots
- [ ] agenix/secrets module (only when real secrets need versioning)
- [ ] Additional compositor profiles (sway/labwc stubs exist upstream)
- [ ] CI check (`nix flake check` on push)
- [ ] Split `hosts/nixos/configuration.nix` remainder into `modules/nixos/`

<div align="center">
    <h2>• thank you •</h2>
    <h3></h3>
</div>

- [Ly-sec/nixos](https://github.com/Ly-sec/nixos) for the flake layout (hosts + modules + desktops + settings switch)
- [Noctara-Dots](https://github.com/deadduck-09/Noctara-Dots) for the config layout
- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) for the README structure
- [Niri](https://github.com/YaLTeR/niri)
- [Noctalia](https://github.com/NoctaliaDev/noctalia-shell)
- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) for the original scaffold
