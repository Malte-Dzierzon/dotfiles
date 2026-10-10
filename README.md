# dotfiles — configs only

Plain app configs. No NixOS, no installer — just files that go
into `~/.config` and `~/.local`.

> Full system (opinionated NixOS + auto-installer) lives on
> [`main`](https://github.com/Malte-Dzierzon/dotfiles/tree/main).

## layout

```
.config/      → ~/.config  (nvim, fish, omp, starship, …)
.local/bin/   → ~/.local/bin  (helper scripts)
wallpapers/   → ~/Pictures/Wallpapers
```

## use

```bash
git clone --branch configs https://github.com/Malte-Dzierzon/dotfiles.git
cp -r dotfiles/.config/* ~/.config/
```

Take what you like, leave the rest.

## theme

Everything follows one palette — Noctalia **Haven**
(`#070e15` bg, `#e9efeb` fg, `#97a6bb` accent).
