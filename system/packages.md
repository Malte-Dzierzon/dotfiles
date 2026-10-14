# Package inventory (from NixOS bundles.nix catalog + live system)

## Core CLI (zypper)
foot kitty git fish starship tmux yazi lazygit btop fastfetch fzf ripgrep fd bat eza zoxide direnv neovim mpv zathura nautilus wl-clipboard libnotify

## Desktop (Umbriel + Noctalia)
Umbriel: build from source (github.com/maltegotech/umbriel or flake input `umbriel`). Noctalia-shell: upstream installer. greetd + noctalia-greeter for login screen.

## Browsers / notes / comms
Zen Browser (upstream tarball), Zed (upstream script), Obsidian (flatpak/appimage), Signal/Flare, Concord (Discord client), Readest (PDF/ebook).

## Dev / AI agents
- omp (Oh My Pi): npm i -g oh-my-pi — config in configs/ai/omp → ~/.config/omp
- pi-coding-agent: npm i -g pi-coding-agent — config in configs/ai/pi-agent → ~/.pi/agent
- opencode: official install script (curl -fsSL https://opencode.ai/install | bash)
- No "Oh My SSH" tool found on system or in repo — nothing to migrate.

## Gaming
- OpenTabletDriver: official .rpm/release (needs udev rules in system/hardware/, uinput kernel module). XP-Pen Deco Pro MW Gen2 profile in configs/gaming/.
- osu!lazer: upstream AppImage/official build; settings NOT safely exportable (client.realm is a binary Realm DB) — re-login manually.
- Prism Launcher: flatpak org.prismlauncher.PrismLauncher; restore prismlauncher.cfg (fix JavaPath to /usr/bin/java) + instance list; game data re-downloaded.
- Steam (native rpm), gamemode, mangohud, proton via Steam.

## Creative
blender inkscape krita godot (all native zypper).

## Hardware extras
headsetcontrol (Logitech PRO X Wireless, needs 70-headsets.rules uaccess), AMD GPU: Mesa-vulkan + vulkan-tools, PipeWire + wireplumber + rtkit, bluetooth, power-profiles-daemon, docker (optional), tailscale (optional).
