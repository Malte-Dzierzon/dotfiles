# AGENTS.md — Regeln für dieses Repo

## Grundsatz: Repo = sauber & deklarativ, lokal = pragmatisch

Das Repo beschreibt den **Soll-Zustand für eine starke Maschine**. Alles was sich
in Nix ausdrücken lässt, gehört deklarativ ins Repo (Flake-Inputs, nixpkgs,
Home-Manager). Auf dem **schwachen Laptop** darf lokal abgewichen werden, ohne
das Repo zu verschmutzen.

## Leistungsprofile (`lysec.buildFromSource`)

- `hosts/nixos/settings.nix`: `buildFromSource = true` (starker PC) /
  `false` (schwacher Laptop).
- `false` → schwere Pakete (z.B. `lmstudio`) werden **nicht** aus Nix gebaut,
  sondern als AppImage/Binary per `scripts/install.sh` besorgt.
- Neue schwere Pakete: in `home/programs/default.nix` per
  `lib.optionals fromSource [...]` gaten, NICHT bedingungslos aufnehmen.
- Faustregel: Build > 10 Min auf dem Laptop → gaten.

## Lokal erlaubt, Repo verboten

| Lokal ok | Repo-Regel |
| :--- | :--- |
| `~/.local/bin/*`-Binaries, AppImages, Symlinks auf `/nix/store` | Nur Skripte + `.desktop`-Dateien einchecken, Binaries in `.gitignore` |
| Absolute Pfade in lokalen Binds (`/home/xealom/.local/bin/...`) | Repo-Configs nutzen `PATH`-Spawns (`environment.localBinInPath`) |
| `/etc/nixos/configuration.nix` anfassen (Notfall-Fix) | Danach **immer** ins Repo zurückportieren (`modules/nixos/`) |
| `nix profile install` (schneller Test) | Danach in `home/programs/default.nix` deklarieren oder wieder entfernen |
| `hosts/nixos/hardware-configuration.nix` (generiert) | Git-ignoriert, nur `.example` pflegen |

## Noctalia

- Shell kommt aus dem Flake-Input (`inputs.noctalia.defaultPackage`),
  eingebunden in `home/programs/default.nix` — KEIN `~/.local/bin`-Symlink.
- Live-Settings: `~/.local/state/noctalia/settings.toml` (Repo-Quelle:
  `home/.local/state/noctalia/settings.toml`).
- Generierte Themes (`gtk-*/noctalia.css`, `kitty`,
  `rofi`) NICHT hand-editieren — Wallpaper-Pipeline schreibt sie neu.

## Workflows

- Edit → `alejandra` → `dry-build` (mit gestagter Hardware) → erst dann `switch`.
- Hardware für Builds: `cp /etc/nixos/hardware-configuration.nix
  hosts/nixos/ && git add -f hosts/nixos/hardware-configuration.nix`,
  danach **sofort** `git reset` + löschen (bleibt git-ignoriert).
- `system.stateVersion` nie heben. `nix.gc` 30d nicht kürzen (Rollback-Gen-Schutz).
