# AGENTS.md — restore xealom's environment on openSUSE Tumbleweed

## What this repo is

Clean config archive of the live NixOS setup. `configs/` holds native app configs with original filenames — copy them to the `$HOME` target listed below. `system/` documents packages, hardware, services. `migration/` has the ordered checklist (`opensuse.md`) and coverage report (`inventory.md`).

## Software stack

Wayland: Umbriel compositor + Noctalia shell/greeter. Terminal: foot (default) + kitty/ghostty/alacritty. Editor: Zed (GUI) + Neovim LazyVim. Browser: Zen. File: nautilus. PDF: zathura. Notes: obsidian. Shell: fish + starship (+ zsh backup). Agents: omp, pi-coding-agent, opencode (all via upstream npm/script, never distro packages).

## Config map (repo → $HOME target)

- configs/desktop/umbriel/* → ~/.config/umbriel/ (all .toml incl. bindings, monitors, input, look, autostart)
- configs/desktop/noctalia/templates+palettes → ~/.config/noctalia/; settings-live.toml → ~/.local/state/noctalia/settings.toml (reference only; Noctalia migrates it — diff, don't overwrite blindly)
- configs/desktop/gtk/3.0+4.0 → ~/.config/gtk-3.0, gtk-4.0; qt/ → ~/.config/qt5ct, qt6ct
- configs/desktop/mimeapps-live.list → ~/.config/mimeapps.list; default-app-roles.toml documents the six roles (terminal foot, editor zeditor, browser zen, file nautilus, pdf zathura, notes obsidian). system/scripts/default-app restores the dispatcher → ~/.local/bin/.
- configs/desktop/rofi walker swaylock mpd cliamp kew sonora rmpc toofan slipper → ~/.config/<same>
- configs/shell/fish → ~/.config/fish; starship/starship.toml → ~/.config/starship.toml; foot kitty ghostty alacritty tmux btop cava fastfetch → ~/.config/<same>
- configs/development/nvim → ~/.config/nvim; zed → ~/.config/zed; yazi → ~/.config/yazi; lazygit → ~/.config/lazygit
- configs/ai/omp → ~/.config/omp; pi-agent → ~/.pi/agent; opencode-package.json is install reference only
- configs/gaming/opentabletdriver-settings.json → ~/.config/OpenTabletDriver/settings.json; prism/*.cfg → ~/.local/share/PrismLauncher/ (fix JavaPath); osu-framework.ini is reference (client.realm DB not portable)
- configs/creative/{blender,inkscape,godot,krita} → ~/.config/<same> (blender: userpref/startup.blend only)

## Install sources

- zypper native: foot kitty git fish tmux yazi btop neovim mpv zathura nautilus blender inkscape krita godot steam gamemode mangohud headsetcontrol pipewire docker tailscale.
- Flatpak: Obsidian, Prism Launcher.
- Upstream only: Zen Browser (tarball), Zed (script), Umbriel (source), Noctalia (upstream), OpenTabletDriver (release .rpm), LM Studio (official installer, ~/LMStudio data excluded), osu!lazer (AppImage), omp/pi-coding-agent (npm -g), opencode (official script).

## Machine-specific (must adapt)

Username `xealom`, monitor names/positions (umbriel/monitors.toml — re-detect), tablet display offset (2560x1440@1280,720 — verify), JavaPath (/usr/bin/java), locale de-DE, absolutely no hardware UUIDs/secrets in repo.

## Restore order

1. zypper base + GPU/Vulkan + PipeWire → reboot, verify. 2. Umbriel + Noctalia + greetd. 3. Copy desktop/gtk/qt/mime configs, test login. 4. Shell + dev tools. 5. Agents (npm/script). 6. Tablet daemon + udev rules + headsetcontrol test. 7. Gaming/creative. 8. Validate: `umbriel --check`, noctalia settings diff, `foot --version`, `nvim --headless +q`, otd daemon status, audio test.

## Validate without disruption

Copy single-app configs to a test user first, or back up existing ~/.config/<app> before overwriting. Never bulk-copy over a live system. JSON/TOML already syntax-checked at archive time.

## Manual approval required

Installing packages, enabling services, udev rules, greeter changes, anything touching auth/credentials (osu login, tailscale up, git signing keys, SSH keys — none archived), and overwriting any existing user config.
