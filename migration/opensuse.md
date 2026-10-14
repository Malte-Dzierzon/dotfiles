# openSUSE Tumbleweed setup checklist

1. Repository klonen und (optional) OpenCode-Bootstrap ausführen:
   `bash migration/bootstrap-opencode.sh --dry-run` prüfen, dann ohne Flag laufen lassen.
   Das installiert nur die OpenCode-CLI (Upstream) und legt die Migrationshinweise unter
   `~/.config/opencode/AGENTS.md` ab (bestehende Notizen bleiben erhalten) — kein Provider,
   keine Zugangsdaten. Danach mit der Checkliste fortfahren (`/connect` für Provider separat).
2. App-Auswahl anhand `apps/app-inventory.md` treffen (nur Spalte „installiert“ + gewählte Katalog-Apps; Systemdeps aus `system/` separat).

3. Install Tumbleweed (KDE-less minimal + Wayland base), user `xealom`, locale de-DE, timezone Europe/Berlin.
4. `sudo zypper dup` to latest; install GPU stack: `Mesa-vulkan-drivers vulkan-tools`; verify `vulkaninfo | grep AMD`.
5. Audio: `pipewire pipewire-pulseaudio wireplumber rtkit bluez`; `systemctl --user enable --now pipewire wireplumber`.
6. Build/install Umbriel (source) + Noctalia shell + greetd greeter (or SDDM fallback). Restore `configs/desktop/umbriel/` → `~/.config/umbriel/`.
7. Restore Noctalia templates/palettes; compare `settings-live.toml` against fresh `~/.local/state/noctalia/settings.toml`.
8. GTK/Qt/mimeapps: copy `configs/desktop/gtk qt mimeapps-live.list`; install `qt5ct qt6ct nwg-look`.
9. Shell: `fish starship foot kitty tmux yazi lazygit btop fastfetch fzf eza zoxide`; copy `configs/shell/*`; `chsh -s /usr/bin/fish`.
10. Dev: `neovim mpv zathura nautilus`; Zen (tarball), Zed (script), Obsidian + Prism (flatpak); copy `configs/development/*`.
11. Agents: `npm i -g oh-my-pi pi-coding-agent`; opencode install script; copy `configs/ai/omp → ~/.config/omp`, `pi-agent → ~/.pi/agent`.
12. Tablet: install OpenTabletDriver rpm, copy `system/hardware/70-opentabletdriver.rules → /etc/udev/rules.d/`, `modprobe uinput`, enable `otd-daemon --user`, restore settings.json, verify XP-Pen area.
13. Headset: `headsetcontrol` + headsets udev rules (see system/hardware/); test Logitech PRO X Wireless.
14. Gaming: Steam + gamemode/mangohud; osu!lazer AppImage (manual login — realm DB not portable); Prism cfg + instances (fix JavaPath).
15. Creative: `blender inkscape krita godot`; restore `configs/creative/*`.
16. Optional: docker, tailscale (`tailscale up` manually), LM Studio (official installer).
17. Validate: `umbriel --check`, `nvim --headless +q`, `foot --version`, audio/tablet/login tests. Get manual approval before each destructive step.
