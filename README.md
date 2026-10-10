<div align="center">

# dotfiles

**Opinionated NixOS — Umbriel + Noctalia, with auto-installer.**

<img src="assets/screenshots/desktop.png" alt="desktop" width="750">

</div>

> Just want the app configs? → [`configs` branch](https://github.com/Malte-Dzierzon/dotfiles/tree/configs)
> (plain `~/.config` files, no NixOS).

## use

One command, from anywhere:

```bash
dot apply    # link configs + dry build + switch + verify
dot dry      # preview, changes nothing
dot verify   # system health (read-only)
dot update   # check repo / pull (--pull) / inputs (--inputs)
dot status   # branch, dirty files, remote lag
dot version  # repo revision + flake pin
```

Your per-machine selection lives in `hosts/nixos/local.nix`
(git-ignored). Remote `main` never touches a live system —
only `dot apply` does.

## install

NixOS 26.05, x86_64.

| Situation | Command |
| :--- | :--- |
| Fresh machine (Minimal ISO) | `REF=<sha> bash <(curl -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/$REF/scripts/live-installer.sh)` |
| Installed NixOS | clone, then `dot apply` |

`REF` pins the revision (`main` floats). Only the small
`live-installer.sh` runs from the network; everything privileged
runs from the cloned checkout.

<details>
<summary><b>Wizard & modes</b></summary>

The wizard asks: keyboard → profile (laptop/desktop) → identity
(user, host, timezone, git) → bundles → review → double confirm.
Nothing happens before that.

Hardware config is always generated on the machine
(`nixos-generate-config`), never copied from the repo.
Symlinks back up as `*.pre-dotfiles`, never overwritten.
Previous generations stay in the boot menu (30d GC).

</details>

## apps

Bundles are picked in the installer (`shell` always on).
One place: `home/programs/bundles.nix`.

| Bundle | Inside |
| :--- | :--- |
| core | fish, git, starship, nix tools, cli utils |
| terminal | foot, kitty, alacritty |
| editor | Zed, Neovim |
| desktop | walker, nautilus, btop, fastfetch |
| browser | Zen (pinned flake input) |
| dev | gh, lazygit, lazydocker, pi-coding-agent |
| latex | texlive-small, texlab, zathura |
| notes | obsidian, readest |
| media | mpd + rmpc, kew, mpv, imv |
| gaming | prismlauncher, steam-run, osu-lazer |
| chat | flare-signal, concord, sonora |
| net | nmap, bluetooth tools |
| fun | toofan typing test |
| shell | Noctalia + greeter (always on) |

## stack

NixOS 26.05 · Umbriel (compositor) · Noctalia (shell, palette **Haven**)
· foot · fish/zsh + starship · Zed/Neovim · Zen · mpd + kew.

<details>
<summary><b>Repo layout</b></summary>

```
flake.nix            inputs (pinned) + nixosConfigurations.nixos
hosts/nixos/         settings.nix (defaults), local.nix (per-machine, ignored)
modules/lysec/       options (username, keyboard, profile, bundles, …)
modules/nixos/       boot/nix/locale/networking/audio/greeter/user
desktops/umbriel/    compositor + home config
home/programs/       bundles.nix (one place for all packages)
home/shell/          fish/git/starship/mpd
dotfiles/            ~/.config + ~/.local mirror (installer symlinks it)
scripts/             lib.sh, ui.sh, apply, update, verify, wizard
```

</details>
