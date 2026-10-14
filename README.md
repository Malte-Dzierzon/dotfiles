# System Backup — openSUSE migration archive

Distro-independent archive of the real working NixOS setup (user `xealom`), prepared for a future openSUSE Tumbleweed migration. No installer, no Nix — just configs plus restoration recipes.

Start with **AGENTS.md**, then follow **migration/opensuse.md**.

Benutzer-App-Liste: **apps/app-inventory.md** (installiert vs. Katalog vs. unverifiziert, mit openSUSE-Installationswegen).

Layout:

```text
configs/      native app configs (copy to $HOME paths per AGENTS.md)
  desktop/    umbriel, noctalia, gtk, qt, mimeapps, launchers, mpd/players
  shell/      fish, starship, foot, kitty, ghostty, alacritty, tmux, btop…
  development/ nvim (LazyVim), zed, yazi, lazygit, git
  ai/         omp, opencode, pi-agent (+ install methods)
  gaming/     OpenTabletDriver XP-Pen profile, prism manifests, osu notes
  creative/   blender, inkscape, godot, krita
system/       packages.md, hardware/ (udev rules, monitors), services/
migration/    opensuse.md (ordered checklist), inventory.md (coverage)
```

Excluded deliberately: secrets, browser profiles, game data, caches, model weights, DBs — see migration/inventory.md.
