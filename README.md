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

NixOS 26.05, x86_64. Pick one of four modes:

| Mode | When | Command |
| :--- | :--- | :--- |
| 🆕 Fresh install | Minimal ISO, empty disk → full setup in `/mnt` | `REF=<sha> bash <(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/$REF/scripts/live-installer.sh)` |
| 🔧 Apply | Installed NixOS → write selection, rebuild | `./scripts/apply.sh` |
| 🔄 Update | New stuff from GitHub, deliberately | `./scripts/update.sh` then `./scripts/apply.sh` |
| ✅ Verify | Something off? Read-only check | `./scripts/verify.sh` |

> `REF` pins the revision (`main` floats — no reproducibility without it).
> Only the ~60-line `live-installer.sh` runs from the network; everything
> privileged happens from the cloned checkout.

<details>
<summary><b>Mode details</b></summary>

**🆕 Fresh install** — boot ISO (UEFI), connect (`nmtui`), prepare `/mnt`
(partition, format, mount), run the command above. The wizard asks
keyboard → profile → identity → bundles → review → double confirmation.
Then: hardware config generated (`nixos-generate-config --root /mnt`, never
copied), dry-build, `nixos-install`, reboot, clone repo, `apply.sh`.

**🔧 Apply** — `apply.sh --dry-run` previews, `--wizard` re-asks, plain
`apply.sh` runs preflight → symlinks (backed up as `*.pre-dotfiles`) →
dry-build → switch → verify. Preflight aborts on Arch dev PC, live ISO,
root, wrong user, dirty tree, or missing hardware config (adopted only
after validation, staged via `git add -f`, always reset after — no UUIDs
on GitHub).

**🔄 Update** — `update.sh` (= `--check`, fetch + show), `--pull` (clean
tree only, then review the diff), `--inputs` (`nix flake update`, unpins —
deliberate). Only `apply.sh` activates anything, per PC. `git pull` on
PC A never changes PC B; inputs stay pinned in `flake.lock`.

**✅ Verify** — fatal FAILs: missing links, missing hardware config,
non-ignored host files, secrets in repo. Warnings only: binaries/XDG on
console systems, missing `local.nix`. Recovery: previous generation in the
boot menu (30d GC protection) → fix → `apply.sh --dry-run` → apply.

**Second PC?** Install minimal NixOS 26.05 (no desktop, EFI, user,
NetworkManager) → `nix-shell -p git curl` → run `bootstrap.sh` the same
way as `live-installer.sh` above → `apply.sh --wizard` → reboot →
`verify.sh`.

</details>

## Setup

Keyboard (de/us/gb/custom, gb-XKB uses the uk console) → console + XKB +
Noctalia greeter + Umbriel.
Profile (laptop/desktop) → quirks only (`intel_vbtn` blacklist on laptop),
never hardware detection.
Selection lives in `hosts/nixos/local.nix` (per machine, git-ignored);
change it via `apply.sh --wizard` or by editing the file.

<img src="assets/screenshots/noctalia.png" alt="Noctalia control center" width="750">

## Apps

One place: `home/programs/bundles.nix`. Pick bundles in the installer;
`shell` (Noctalia + greeter) is always on.

| Bundle | What's inside |
| :----- | :------------ |
| core | fish, git, starship, nix tools (`nh`, `nil`, `alejandra`, `nix-search-tv`, `jq`), cli utils |
| terminal | foot, kitty, alacritty, ghostty |
| editor | Zed, Neovim |
| desktop | walker, nautilus, wayland helpers, btop, fastfetch |
| browser | Zen (pinned flake input) |
| dev | `gh`, lazygit, lazydocker, pi-coding-agent |
| latex | texlive-small, texlab, zathura |
| notes | obsidian, zettlr, readest |
| media | mpd + mpc + rmpc, kew, mpv, imv |
| gaming | prismlauncher, steam-run, osu-lazar |
| chat | flare-signal, concord, sonora |
| net | nmap, wireshark, bluetooth tools |
| fun | toofan typing test |
| shell | Noctalia + greeter (always on) |

<details>
<summary><b>Full package list</b></summary>

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
| Terminal | foot (default) / kitty / alacritty / ghostty |
| Prompt | fish + starship |
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
home-entry.nix          home-manager entrypoint (identity + symlinks)
configs/dotconfig/      plain app configs → ~/.config (no Nix string escaping)
home/.local/bin/        helper scripts  scripts/  live-installer.sh, install-wizard.sh, apply.sh, update.sh, verify.sh, lib.sh (+ install.sh shim, bootstrap.sh)
```

- **Hardware config** is host-specific: generated via `nixos-generate-config --root /mnt` (ISO) or adopted after validation (apply.sh) — never copied from the repo, never commit it.
- **Live state** (`~/.local/state/noctalia/settings.toml`, wallpapers in `~/Pictures/Wallpapers/`) is not versioned — the tracked copy under `home/.local/state/noctalia/settings.toml` is the starting point.
- **External binaries** (`~/.local/bin/{omp,cliamp-real,zapfast-real,pakmc-bin}`) have no nixpkgs source; the installer warns if missing.
- **Neovim** is stock LazyVim plus a look-only layer (`minimal.lua`: no icons, transparent, square borders, base16-Noctalia via `matugen.lua`), fully tracked under `configs/dotconfig/nvim/` and symlinked to `~/.config/nvim`; LSPs/formatters come from Mason (`stylua`, `shfmt`, `tree-sitter-cli` installed, rest on demand).
- **LaTeX** had no local toolchain — `texlive scheme-small` + `texlab` + `zathura` are now declared (bundle `latex`); untested against a real `.tex` document.
- **Still manual/experimental**: partitioning (guide, no disko), LUKS encryption, Wi-Fi in the installer, `wlsunset` coordinates don't follow the timezone automatically, Noctalia settings outputs (`eDP-1` etc.) are per-machine live state.

</details>
