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

NixOS 26.05, x86_64. Four modes — fresh install, apply, update, verify.
`install.sh` remains as a shim (`--dry-run/--no-rebuild/--wizard/
--verify-only` → below).

### Mode 1 — Fresh install from the Minimal ISO (target: /mnt)

1. Boot the minimal ISO (UEFI), connect to the network (`nmtui`).
2. Prepare `/mnt` (single-disk example — adjust the device, ERASES data
   on these partitions):
   ```bash
   sudo parted /dev/<disk> -- mklabel gpt mkpart ESP fat32 1MiB 1GiB mkpart root ext4 1GiB 100% set 1 esp on
   sudo mkfs.fat -F32 /dev/<disk>1 && sudo mkfs.ext4 -L nixos /dev/<disk>2
   sudo mount /dev/disk/by-label/nixos /mnt && sudo mkdir -p /mnt/boot && sudo mount /dev/<disk>1 /mnt/boot
   ```
3. Start the wizard (only THIS code runs from the network — ~60 lines,
   readable; everything privileged happens afterwards from the cloned checkout):
   ```bash
   REF=<commit-sha>; bash <(curl --proto '=https' --tlsv1.2 -fsSL \
     https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/$REF/scripts/live-installer.sh)
   ```
   (`REF` pins the revision; `main` floats. No reproducibility without REF.)
4. The wizard asks: **keyboard** (de/us/gb/custom) → **profile**
   (laptop/desktop) → **identity** (user, host, timezone, locales, git) →
   **bundles** (core/terminal/editor/desktop/browser/dev/latex/notes/media/
   gaming/chat/net/fun; shell+greeter always on) → **review** → **double
   confirmation** (nothing happens before that).
5. Then: `nixos-generate-config --root /mnt` (hardware NEVER copied from
   the repo), dry-build, `nixos-install --root /mnt --flake $REPO#nixos`,
   reboot, log in as user, set `passwd`, freshly clone the repo into
   `~/Projects/dotfiles`, `./scripts/apply.sh`.
6. Verify: `./scripts/verify.sh` (green except possibly console warnings).

Keyboard applies to console + XKB + Noctalia greeter + Umbriel (follows the
system default; gb-XKB uses the uk console). Profile only controls quirks
(intel_vbtn blacklist on laptop only) — never hardware detection.

### Mode 2 — Apply on installed NixOS

```bash
cd ~/Projects/dotfiles
./scripts/apply.sh --dry-run   # preview, changes nothing
./scripts/apply.sh --wizard    # re-answer (TUI), then apply
./scripts/apply.sh             # preflight → symlinks → dry-build → switch → verify
```

Preflight aborts on: not NixOS (protects the Arch dev PC), live ISO
(`nixos-rebuild` would only change RAM), root user, wrong user,
dirty tree, missing hardware config (adopted only after validation, never
blindly copied). The hardware config is only staged via `git add -f`
and always reset/deleted afterwards — no UUIDs on GitHub.

### Mode 3 — Updates (explicit, never automatic)

```bash
./scripts/update.sh           # = --check: fetch + show what is new upstream
./scripts/update.sh --pull    # only on clean tree; then review the DIFF
./scripts/update.sh --inputs  # nix flake update (unpins — deliberate)
./scripts/apply.sh            # only THIS activates anything (per PC)
```

Lifecycle: install → local checkout is the source → deliberately pull →
review → deliberately apply. `git pull` on PC A never changes PC B.
Flake inputs stay pinned (`flake.lock`) until `--inputs` runs.

### Mode 4 — Verify & Repair

```bash
./scripts/verify.sh   # read-only: symlinks, binaries, secrets, host files
```

Fatal FAILs: missing config links, missing hardware config, non-ignored
host files, secrets in the repo. Warnings (no exit 1): binaries/XDG on
console-only systems, missing `local.nix`. Recovery after a bad rebuild:
pick the previous generation in the boot menu (30d GC protection), fix
`local.nix`/modules, `apply.sh --dry-run`, apply again.

### Files & categories

| Category | Where | Effect |
| :--- | :--- | :--- |
| declarative | Nix/Home-Manager (`home-entry.nix`) | active only after rebuild |
| generated | `hosts/nixos/local.nix` + `hardware-configuration.nix` (git-ignored!) | per machine, installer selection |
| deployed | `~/.config` symlinks (`*.pre-dotfiles` backup, never overwritten) | explicit via apply.sh |
| local | `~/Pictures/Wallpapers`, secrets, `~/.local/state` | stays put, never versioned |

Change the selection: `apply.sh --wizard` or edit `local.nix` → `apply.sh`.
Change the core list: `home/programs/bundles.nix` (ONE place) → commit → per PC
`update.sh --pull` + `apply.sh`. Theme: Noctalia palette Haven
(`background #070e15`, `foreground #e9efeb`, `accent #97a6bb`); do NOT
hand-edit generated theme files (gtk/kitty/rofi).
Machine-specific settings (outputs, scaling) do NOT belong in shared
configs — add locally, don't commit.

### Second PC (existing minimal NixOS → full setup)

1. Install minimal NixOS 26.05 (no desktop, EFI/systemd-boot, create user,
   enable NetworkManager), boot into the console.
2. As user with network: `nix-shell -p git curl` (one shell).
3. `REF=<sha> bash <(curl --proto '=https' --tlsv1.2 -fsSL
   https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/$REF/scripts/bootstrap.sh)`
   (bootstrap = checkout helper for INSTALLED systems, aborts on
   live ISO/Arch/dirty tree).
4. `apply.sh --wizard` → answer → dry-build → switch → reboot →
   Noctalia greeter login → `verify.sh`.

Stay manual: partitions/user/network of the base install, sudo password
on first run, external binaries (`~/.local/bin/{omp,cliamp-real,
zapfast-real,pakmc-bin}` — installer warns), `~/Music` contents,
secrets/logins (GitHub, Bitwarden, Wi-Fi).
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
hosts/nixos/            settings.nix (defaults), default.nix, local.nix(.example) + hardware-configuration.nix(.example) — local+hw gitignored
modules/lysec/          options (username, keyboard, profile, locales, bundles, ...)
modules/nixos/          boot/nix/locale/networking/audio/greeter/user (locale+greeter+boot follow lysec)
desktops/umbriel/       umbriel nixos.nix + home.nix (config follows system XKB, no outputs in repo)
desktops/shared/        shared wayland home config
home/programs/          bundles.nix (ONE place for all packages) + default.nix (resolve + fromSource gate)
home/shell/             fish/git/starship/mpd config
home-entry.nix          home-manager entrypoint (identity + symlinks)
configs/dotconfig/      plain app configs → ~/.config (no Nix string escaping)
home/.local/bin/        helper scripts  scripts/  live-installer.sh, install-wizard.sh, apply.sh, update.sh, verify.sh, lib.sh (+ install.sh shim, bootstrap.sh)
```

## Notes

- **Hardware config** is host-specific: generated via `nixos-generate-config --root /mnt` (ISO) or adopted after validation (apply.sh) — never copied from the repo, never commit it.
- **Live state** (`~/.local/state/noctalia/settings.toml`, wallpapers in `~/Pictures/Wallpapers/`) is not versioned — the tracked copy under `home/.local/state/noctalia/settings.toml` is the starting point.
- **External binaries** (`~/.local/bin/{omp,cliamp-real,zapfast-real,pakmc-bin}`) have no nixpkgs source; the installer warns if missing.
- **Neovim** is stock LazyVim plus a look-only layer (`minimal.lua`: no icons, transparent, square borders, base16-Noctalia via `matugen.lua`), fully tracked under `configs/dotconfig/nvim/` and symlinked to `~/.config/nvim`; LSPs/formatters come from Mason (`stylua`, `shfmt`, `tree-sitter-cli` installed, rest on demand).
- **LaTeX** had no local toolchain — `texlive scheme-small` + `texlab` + `zathura` are now declared (bundle `latex`); untested against a real `.tex` document.
- **Still manual/experimental**: partitioning (guide, no disko), LUKS encryption, Wi-Fi in the installer, `wlsunset` coordinates don't follow the timezone automatically, Noctalia settings outputs (`eDP-1` etc.) are per-machine live state.
