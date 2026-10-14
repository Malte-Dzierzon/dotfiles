# Inventory — what is archived, missing, excluded

## Archived (real working configs)
Umbriel (all TOML), Noctalia templates/palettes + live settings.toml reference, GTK3/4, Qt5/6ct, mimeapps, rofi/walker/swaylock, mpd/cliamp/kew/sonora/rmpc/toofan/slipper, fish, starship, foot/kitty/ghostty/alacritty, tmux, btop/cava/fastfetch, nvim LazyVim, zed, yazi, lazygit, omp, opencode ref, pi-agent, OpenTabletDriver XP-Pen settings, Prism cfg + instance list, osu framework.ini ref, blender/inkscape/godot/krita settings, default-app dispatcher + roles, udev rules (tablet/headsets), packages/services/hardware docs.

## Missing / non-exportable (manual on new machine)
osu!lazer login + client.realm DB, browser (Zen) profile, Obsidian vault content, Signal/Concord sessions, SSH keys (~/.ssh empty — in password manager), git signing keys, tailscale auth, LM Studio models, Noctalia notification history, monitor names (re-detect).

## Deliberately excluded
Secrets/tokens/cookies/auth DBs, browser profiles, ~/.ssh (empty anyway), Prism instances/game assets (~500MB), osu cache/realm binaries, krita resource cache (~100MB), xppentablet app install (~50MB), opencode/omp DBs + logs, LM Studio models (~GBs), flatpak ~/.var data, fonts binaries (names documented), hardware UUIDs, machine-id.

## No "Oh My SSH"
Searched repo + $HOME + PATH: no tool named Oh-My-SSH/ohmyssh found. Nothing archived; not invented.

## App-Liste
Zentrale Benutzer-App-Liste: `apps/app-inventory.md` (inkl. Neu-entdeckt/entfallen-Abgleich).

## OpenCode-Bootstrap
`migration/bootstrap-opencode.sh` (nur OpenCode-CLI + `configs/ai/opencode/AGENTS.md` → `~/.config/opencode/AGENTS.md`, idempotent, `--dry-run`). Kein Provider/Modell, keine Secrets.
