# dotfiles — configs only

Plain app configs, no NixOS. Mirror of `~/.config` + `~/.local`
from the [main branch](https://github.com/Malte-Dzierzon/dotfiles)
(opinionated NixOS setup — installer, modules, system).

## layout

```
.config/      → ~/.config (nvim, fish, omp, starship, ...)
.local/bin/   → ~/.local/bin (helper scripts)
wallpapers/   → ~/Pictures/Wallpapers
```

## use

```bash
git clone --branch configs https://github.com/Malte-Dzierzon/dotfiles.git
cp -r dotfiles/.config/* ~/.config/
```

Pick what you like, leave the rest. Updated alongside main.
