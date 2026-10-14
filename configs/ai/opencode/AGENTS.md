# Migration instructions for OpenCode (global)

> Source: personal dotfiles `system-backup` branch (distro-independent config archive).
> This file is a template. The bootstrap merges the marked section into
> `~/.config/opencode/AGENTS.md` without touching your own notes.

This repository is a personal configuration archive, NOT an OS installer.
Before changing anything, read in the repo root: `AGENTS.md`, then
`apps/app-inventory.md`, `migration/opensuse.md`, `migration/inventory.md`.

## Working rules on openSUSE Tumbleweed

- Inspect existing configs first (`~/.config/<app>`, `~/.local/state/...`); never bulk-overwrite a live system. Back up per-app before replacing.
- Install packages per `apps/app-inventory.md`: native `zypper` presidio, Flatpak, or official upstream installer as documented. No new package manager, no auto-installer.
- Fast-moving AI tools (opencode, omp, pi-coding-agent) only via their official install/update path, never distro packages.
- Restore order: base + AMD/Vulkan + PipeWire → Umbriel + Noctalia + greeter → desktop/gtk/qt/mime → shell/dev → agents → tablet/udev + headset → gaming/creative.
- Hardware-bound values must be re-checked, never copied blindly: monitor names/positions (`configs/desktop/umbriel/monitors.toml`), tablet display offset, `JavaPath`, username/home paths, locale (`de-DE`).

## Safety

- Ask before: installing packages, enabling services, writing udev rules, greeter/login changes, overwriting any existing user file, anything touching auth/credentials.
- After each config change run the matching check (`umbriel --check`, `nvim --headless +q`, daemon status, settings diff) and only report verified results.
- Never reconstruct secrets or write tokens/keys into git. Missing credentials are manual steps, not gaps to fill.
