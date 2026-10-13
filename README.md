<div align="center">

# dotfiles

**My NixOS setup — Umbriel + Noctalia, with a small installer.**

![](https://img.shields.io/github/last-commit/Malte-Dzierzon/dotfiles?&style=flat-square&color=8ad7eb&logo=git&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/NixOS-26.05-5277C3?style=flat-square&logo=nixos&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/Umbriel-compositor-D55C44?style=flat-square&logo=wayland&logoColor=D9E0EE&labelColor=1E202B)
![](https://img.shields.io/badge/Noctalia-shell-0e0e43?style=flat-square&logoColor=D9E0EE&labelColor=1E202B)
[![](https://img.shields.io/badge/foot-terminal-4C566A?style=flat-square&labelColor=1E202B)](https://codeberg.org/dnkl/foot)

<img src="assets/screenshots/desktop.png" alt="desktop" width="750">

</div>

> Looking for just the app configs? See the [`configs` branch](https://github.com/Malte-Dzierzon/dotfiles/tree/configs) for plain `~/.config` files without the NixOS configuration.

## Desktop setup

NixOS 26.05 · Umbriel · Noctalia · foot / Kitty · fish/zsh + Starship · Zed/Neovim · Zen · Yazi · Walker.

<details>
<summary><b>The dot command</b></summary>

The `dot` command provides shortcuts for applying, checking, and managing the configuration.

```bash
dot          # interactive menu (check/apply/apps/restore)
dot ls       # bundles: contents + enabled state
dot apps     # select bundles for this machine (saves, no activation)
dot check    # read-only validation (--full adds flake eval + dry build)
dot apply    # link configs, build, confirm, switch, verify
dot restore  # generation rollback info (system only, not source files)
dot help     # command reference
```

Helpers kept outside the core: `default-app` (role launcher), `mime`
(`--fix` aligns MIME with roles), `applist`, `mode` (desktop/headless),
`verify`. Git is yours: normal `git` commands, no `dot sync/save` wrapper.

</details>

<details>
<summary><b>Configuration</b></summary>

### Desktop settings

The Umbriel configuration is in `dotfiles/.config/umbriel/`. The main `config.toml` loads the individual files in order.

| File | Settings |
|---|---|
| `bindings.toml` | Keybindings |
| `input.toml` | Keyboard repeat, touchpad, and cursor theme |
| `look.toml` | Gaps, borders, blur, and shadows |
| `monitors.toml` | Display modes for each output |
| `autostart.toml` | Applications started at login |
| `env.toml` | Environment variables and hot corners |

### Default applications

Application roles are defined in `config/defaults.toml`. Keybindings use `default-app <role>`, so changing a role updates the applications used by the corresponding shortcuts.

Terminal-based editors such as Neovim are opened in the configured terminal automatically.

| Role | Default | Example |
|---|---|---|
| `terminal` | foot | `default-app --set terminal kitty` |
| `editor` | zeditor (Zed) | `default-app --set editor nvim` |
| `browser` | zen | `default-app --set browser firefox` |
| `file` | nautilus | `default-app --set file thunar` |
| `pdf` | zathura | `default-app --set pdf evince` |
| `notes` | obsidian | `default-app --set notes codium` |

```bash
default-app --list               # show available roles
default-app --set editor nvim    # change the default editor
dot mime                         # check MIME associations
dot check                        # validate the configuration
dot apply                        # build (with preview) and apply
```

</details>

<details>
<summary><b>Installation</b></summary>

Requires an installed NixOS 26.05 system on `x86_64`.

```bash
git clone https://github.com/Malte-Dzierzon/dotfiles.git
cd dotfiles
./install.sh
```

The wizard collects the keyboard layout, device profile, user and host details, timezone, Git settings, and application bundles. It shows the selections for review before applying them.

If `hosts/nixos/local.nix` is already configured, you can run the apply script directly:

```bash
./scripts/apply.sh
```

Applications installed separately from Nix remain usable. The apply script links their configuration files as well; missing application binaries produce warnings rather than stopping the process. Use `dot apps` to change the selected bundles later.

The hardware configuration is generated locally with `nixos-generate-config` rather than copied from the repository. Existing files are backed up with the `.pre-dotfiles` suffix instead of being overwritten. Previous system generations are retained for rollback, with garbage collection configured for 30 days.

</details>

<details>
<summary><b>Applications</b></summary>

Application bundles are selected during installation. The `shell` bundle is always enabled. Bundle definitions are maintained in `home/programs/bundles.nix`.

| Bundle | Includes |
|---|---|
| core | [fish](https://github.com/fish-shell/fish-shell), [Git](https://github.com/git/git), [Starship](https://github.com/starship/starship), [Nix tools](https://github.com/NixOS/nix), CLI utilities |
| terminal | [foot](https://codeberg.org/dnkl/foot), [Kitty](https://github.com/kovidgoyal/kitty), [Alacritty](https://github.com/alacritty/alacritty) |
| editor | [Zed](https://github.com/zed-industries/zed), [Neovim](https://github.com/neovim/neovim) |
| desktop | [Walker](https://github.com/abenz1267/walker), [Nautilus](https://github.com/GNOME/nautilus), [btop](https://github.com/aristocratos/btop), [Fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| browser | [Zen](https://github.com/zen-browser/desktop) (pinned flake input) |
| dev | [GitHub CLI](https://github.com/cli/cli), [lazygit](https://github.com/jesseduffield/lazygit), [lazydocker](https://github.com/jesseduffield/lazydocker), [pi-coding-agent](https://github.com/badlogic/pi-mono) |
| notes | [Obsidian](https://github.com/obsidianmd/obsidian-releases), [Readest](https://github.com/readest/readest) |
| media | [MPD](https://github.com/MusicPlayerDaemon/MPD), [rmpc](https://github.com/mierak/rmpc), [kew](https://github.com/ravachol/kew), [mpv](https://github.com/mpv-player/mpv), [imv](https://github.com/eXeC64/imv) |
| gaming | [Prism Launcher](https://github.com/PrismLauncher/PrismLauncher), [steam-run](https://github.com/NixOS/nixpkgs/tree/nixos-26.05/pkgs/by-name/st/steam-run), [osu! lazer](https://github.com/ppy/osu) |
| chat | [Flare Signal](https://gitlab.com/schmiddi-on-mobile/flare), [Concord](https://github.com/chojs23/concord), [Sonora](https://github.com/sonorahq/sonora) |
| net | [Nmap](https://github.com/nmap/nmap), Bluetooth tools |
| fun | [Toofan](https://github.com/vyrx-dev/toofan) |
| shell | [Noctalia](https://github.com/noctalia-dev/noctalia) + [Noctalia Greeter](https://github.com/noctalia-dev/noctalia-greeter) (always enabled) |

</details>

<details>
<summary><b>Repository layout</b></summary>

```text
.
├── assets/
│   └── screenshots/
│       ├── desktop.png
│       └── noctalia.png
├── config/
│   └── defaults.toml
├── desktops/
│   ├── shared/
│   │   └── home.nix
│   └── umbriel/
│       ├── home.nix
│       └── nixos.nix
├── dotfiles/
│   ├── .config/
│   │   ├── foot/
│   │   ├── kitty/
│   │   ├── noctalia/
│   │   ├── nvim/
│   │   ├── opencode/
│   │   ├── umbriel/
│   │   ├── walker/
│   │   ├── yazi/
│   │   ├── zed/
│   │   └── ...
│   └── .local/
│       ├── bin/
│       ├── share/
│       └── state/
├── home/
│   ├── programs/
│   │   ├── bundles.nix
│   │   └── default.nix
│   └── shell/
│       └── default.nix
├── hosts/
│   └── nixos/
│       ├── settings.nix
│       ├── local.nix.example
│       └── hardware-configuration.nix.example
├── modules/
│   ├── lysec/
│   │   ├── default.nix
│   │   └── options.nix
│   └── nixos/
│       ├── audio.nix
│       ├── boot.nix
│       ├── greeter.nix
│       ├── locale.nix
│       ├── networking.nix
│       ├── nix.nix
│       ├── tablet.nix
│       └── user.nix
├── scripts/
│   ├── applist.sh
│   ├── apply.sh
│   ├── apps.sh
│   ├── check.sh
│   ├── dot
│   ├── install-wizard.sh
│   ├── lib.sh
│   ├── mime.sh
│   ├── mode.sh
│   ├── ui.sh
│   └── verify.sh
├── install.sh
├── .gitignore
├── AGENTS.md
├── flake.lock
├── flake.nix
├── home-entry.nix
└── README.md
```

The root `.config/opencode/` directory contains local development tooling. It is untracked and is not linked into `$HOME`. The OpenCode configuration managed by this repository is in `dotfiles/.config/opencode/`.

</details>
