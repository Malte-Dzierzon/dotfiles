<div align="center">

# laptop dotfiles

**NixOS · niri + Noctalia — reines Config-Backup (kein Installer).**

<img src="Pictures/preview/desktop_overview.png" alt="desktop" width="750">

</div>

> Lesekopie meines Setups. Kein `install.sh`, kein `bootstrap.sh`, kein
> NixOS-Modul — nur Dateien, die man direkt lesen und per Hand übernehmen
> kann. Der Auto-Installer lebt auf `main`.

## Inhalt

```
configs/dotconfig/   → ~/.config/  (alle App-Configs, eine Theme-Quelle: Noctalia „Haven")
home/.local/bin/     → ~/.local/bin/ (kleine Helper-Skripte)
Pictures/preview/    → Screenshots als Referenz
```

Wallpaper-Sammlung (`~/Pictures/Wallpapers/`, ~66 MB) ist nicht im Repo —
nur die Vorschau-Bilder hier.

## Übernehmen

```bash
# einzelne Config lesen und per Hand verlinken, z.B.:
ln -s ~/dotfiles-laptop/configs/dotconfig/foot ~/.config/foot
```

## Theme

Eine Quelle: Noctalia-Palette **Haven** (`background #070e15`,
`foreground #e9efeb`, `accent #97a6bb`). niri, foot, GTK, Qt, yazi, zed,
starship, btop u.a. lesen sie. Noctalia schreibt generierte Dateien bei
Theme-Wechsel neu — das erscheint hier bewusst als `git diff`.

## Stack (Referenz)

NixOS 26.05 · niri / umbriel · Noctalia (Bar, Launcher, Theming) ·
foot / kitty / alacritty / ghostty · fish + starship · Zed / Neovim ·
Zen · mpd + rmpc · btop, cava, fastfetch · walker · yazi / Nautilus

<img src="Pictures/preview/noctalia.png" alt="Noctalia control center" width="750">
