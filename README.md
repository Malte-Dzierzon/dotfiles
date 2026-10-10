<div align="center">

# dotfiles

**Umbriel + Noctalia — personal NixOS auto-installer.**

<img src="assets/screenshots/desktop.png" alt="desktop" width="750">

</div>

## Install

NixOS 26.05, x86_64. Pick one of four modes:

| Mode | When | Command |
| :--- | :--- | :--- |
| Fresh install | New machine, Minimal ISO, blank disk | `REF=<sha> bash <(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/$REF/scripts/live-installer.sh)` |
| Apply | Installed NixOS, activate your selection | `./scripts/apply.sh` |
| Update | Fetch upstream changes, deliberately | `./scripts/update.sh`, then `./scripts/apply.sh` |
| Verify | Something off? Read-only health check | `./scripts/verify.sh` |

> `REF` pins the revision (`main` floats — no reproducibility without it).
> Only the ~60-line `live-installer.sh` runs from the network; everything
> privileged happens from the cloned checkout.

<details>
<summary><b>Mode details</b></summary>

#### Fresh install

Boot the ISO (UEFI), connect with `nmtui`, prepare `/mnt`
(partition, format, mount), run the command from the table above.

The wizard asks, in order:

1. **Keyboard** — de / us / gb / custom
2. **Profile** — laptop / desktop
3. **Identity** — user, host, timezone, locales, git
4. **Bundles** — pick from the Apps table below (`shell` always on)
5. **Review** — check the plan
6. **Double confirmation** — nothing happens before this

Then: hardware config is generated
(`nixos-generate-config --root /mnt`, never copied from the repo),
dry-build, `nixos-install --root /mnt --flake $REPO#nixos`, reboot,
log in, set `passwd`, clone the repo to `~/Projects/dotfiles`,
run `./scripts/apply.sh`.

#### Apply

```bash
./scripts/apply.sh --dry-run   # preview, changes nothing
./scripts/apply.sh --wizard    # re-answer, then apply
./scripts/apply.sh             # preflight → symlinks → dry-build → switch → verify
```

Preflight aborts on: Arch dev PC, live ISO, root user, wrong user,
dirty tree, missing hardware config (adopted only after validation,
staged via `git add -f`, always reset afterwards — no UUIDs on GitHub).
Symlinks are backed up as `*.pre-dotfiles`, never overwritten.

#### Update

```bash
./scripts/update.sh            # = --check: fetch + show what is new
./scripts/update.sh --pull     # clean tree only, then review the diff
./scripts/update.sh --inputs   # nix flake update (unpins — deliberate)
./scripts/apply.sh             # only THIS activates anything, per PC
```

`git pull` on PC A never changes PC B. Inputs stay pinned in
`flake.lock` until `--inputs` runs.

#### Verify

Fatal FAILs: missing links, missing hardware config, non-ignored host
files, secrets in the repo. Warnings only: binaries/XDG on console
systems, missing `local.nix`. Recovery: previous generation in the boot
menu (30d GC protection) → fix → `apply.sh --dry-run` → apply.

#### Second PC

Install minimal NixOS 26.05 (no desktop, EFI, user, NetworkManager),
then `nix-shell -p git curl`, run `bootstrap.sh` the same way as
`live-installer.sh` above, `apply.sh --wizard`, reboot, `verify.sh`.

</details>

## Setup

```bash
cd ~/Projects/dotfiles
./scripts/apply.sh --dry-run   # preview, changes nothing
./scripts/apply.sh --wizard    # change selection (keyboard, bundles, identity...)
./scripts/apply.sh             # apply for real
./scripts/update.sh --pull     # get latest from GitHub (review the diff!)
./scripts/verify.sh            # read-only health check
```

Your selection lives in `hosts/nixos/local.nix` (per machine,
git-ignored). Change the app set in `home/programs/bundles.nix`
(one place) → commit → `update.sh --pull` + `apply.sh` per PC.

## Apps

Pick bundles in the installer; `shell` (Noctalia + greeter) is always on.

| Bundle | What's inside |
| :----- | :------------ |
| core | fish, git, starship, nix tools (`nh`, `nil`, `alejandra`, `nix-search-tv`, `jq`), cli utils |
| terminal | foot, kitty, alacritty |
| editor | Zed, Neovim |
| desktop | walker, nautilus, wayland helpers, btop, fastfetch |
| browser | Zen (pinned flake input) |
| dev | `gh`, lazygit, lazydocker, pi-coding-agent |
| latex | texlive-small, texlab, zathura |
| notes | obsidian, readest |
| media | mpd + mpc + rmpc, kew, mpv, imv |
| gaming | prismlauncher, steam-run, osu-lazar |
| chat | flare-signal, concord, sonora |
| net | nmap, bluetooth tools |
| fun | toofan typing test |
| shell | Noctalia + greeter (always on) |

<details>
<summary><b>Full package list</b></summary>

| App | Purpose |
| :-- | :------ |
| foot / kitty / alacritty | terminals |
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
| obsidian, readest | notes / reading |
| gh, lazygit, lazydocker | git / docker |
| bitwarden-cli | passwords |
| nmap, iw, bluez | network / bluetooth |
| prismlauncher, steam-run, osu-lazer-bin | gaming |
| concord, flare-signal | chat |
| pi-coding-agent, nodejs, python3 | dev runtimes |
| texlive (scheme-small), texlab, zathura | LaTeX toolchain + PDF viewer |
| nix-search-tv, nil, alejandra, nh, jq | nix tooling |
| wl-clipboard, grim, slurp, wlsunset, swaylock, xwayland-satellite, polkit_gnome | wayland helpers |
| eza, fzf, zoxide, bat, fd, ripgrep, tmux, starship, git, tree, unzip, zip, file, wget, psmisc, cava, gdu, ffmpeg, appimage-run, xdg-utils, file-roller, adwaita-icon-theme, yaru-theme, qt6ct, inkscape, lmstudio (buildFromSource only) | cli / utils / assets |

</details>

## Theme

Single source: Noctalia palette **Haven** (`background #070e15`,
`foreground #e9efeb`, `accent #97a6bb`). Every app consumes it — umbriel,
foot, GTK, Qt, yazi, zed, starship, btop, walker. Generated files are
committed as a starting point; Noctalia rewrites them on theme change,
which shows up as an intentional `git diff`. Machine-specific settings
(outputs, scaling) don't belong in shared configs — add locally, don't
commit.

## Stack

| Layer | Choice |
| :---- | :----- |
| Distro | NixOS 26.05 |
| Compositor | Umbriel |
| Shell | Noctalia (bar, launcher, theming) |
| Terminal | foot (default) / kitty / alacritty |
| Prompt | fish / zsh + starship |
| Editor | Zed (default) / Neovim |
| Browser | Zen (pinned flake input) |
| Files | Nautilus / Yazi |
| Music | mpd + mpc + rmpc, kew, cliamp |
| Launcher | walker |

<details>
<summary><b>Repo layout & notes</b></summary>

```
flake.nix               inputs (pinned in flake.lock) + nixosConfigurations.nixos (lysec = mkDefault settings.nix)
hosts/nixos/            settings.nix (defaults), default.nix, local.nix(.example) + hardware-configuration.nix(.example) — local+hw gitignored
modules/lysec/          options (username, keyboard, profile, locales, bundles, ...)
modules/nixos/          boot/nix/locale/networking/audio/greeter/user (locale+greeter+boot follow lysec)
desktops/umbriel/       umbriel nixos.nix + home.nix (config follows system XKB, no outputs in repo)
desktops/shared/        shared wayland home config
home/programs/          bundles.nix (ONE place for all packages) + default.nix (resolve + fromSource gate)
home/shell/             fish/git/starship/mpd config
home-entry.nix          home-manager entrypoint (identity + fonts; ~/.config owns the installer, see AGENTS.md)
dotfiles/.config/      plain app configs → ~/.config (no Nix string escaping)
dotfiles/.local/bin/        helper scripts  scripts/  live-installer.sh, install-wizard.sh, apply.sh, update.sh, verify.sh, lib.sh (+ install.sh shim, bootstrap.sh)
```

- **Hardware config** is host-specific: generated via `nixos-generate-config --root /mnt` (ISO) or adopted after validation (apply.sh) — never copied from the repo, never commit it.
- **Live state** (`~/.local/state/noctalia/settings.toml`, wallpapers in `~/Pictures/Wallpapers/`) is not versioned — the tracked copy under `dotfiles/.local/state/noctalia/settings.toml` is the starting point.
- **External binaries** (`~/.local/bin/{zapfast-real,pakmc-bin}`, `~/.local/share/filius/filius.jar`) have no nixpkgs source; the installer warns if missing. omp/cliamp come from Nix (flake input / nixpkgs).
- **Neovim** is stock LazyVim plus a look-only layer (`minimal.lua`: no icons, transparent, square borders, base16-Noctalia via `matugen.lua`), fully tracked under `dotfiles/.config/nvim/` and symlinked to `~/.config/nvim`; LSPs/formatters come from Mason (`stylua`, `shfmt`, `tree-sitter-cli` installed, rest on demand).
- **LaTeX** had no local toolchain — `texlive scheme-small` + `texlab` + `zathura` are now declared (bundle `latex`); untested against a real `.tex` document.
- **Still manual/experimental**: partitioning (guide, no disko), LUKS encryption, Wi-Fi in the installer, `wlsunset` coordinates don't follow the timezone automatically, Noctalia settings outputs (`eDP-1` etc.) are per-machine live state.

</details>
