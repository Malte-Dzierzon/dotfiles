# AGENTS.md — Regeln für dieses Repo

## Grundsatz: Repo = sauber & deklarativ, lokal = pragmatisch

Das Repo beschreibt den **Soll-Zustand für eine starke Maschine**. Alles was sich
in Nix ausdrücken lässt, gehört deklarativ ins Repo (Flake-Inputs, nixpkgs,
Home-Manager). Auf dem **schwachen Laptop** darf lokal abgewichen werden, ohne
das Repo zu verschmutzen.

## Leistungsprofile (`lysec.buildFromSource`)

- `hosts/nixos/settings.nix`: `buildFromSource = false` (schwacher Laptop) /
  `true` (starker PC). Installer-Profil `desktop` setzt NICHT automatisch
  `true` — bewusst pro Maschine in `hosts/nixos/local.nix` waehlen.
- `false` → schwere Pakete (z.B. `lmstudio`) werden **nicht** aus Nix gebaut,
  sondern als AppImage/Binary je Rechner besorgt (Installer warnt nur).
- Neue schwere Pakete: in `home/programs/bundles.nix` ins passende Bundle,
  zusaetzlich per `lib.optionals fromSource [...]` in
  `home/programs/default.nix` gaten, NICHT bedingungslos aufnehmen.
- Faustregel: Build > 10 Min auf dem Laptop → gaten.

## Installer-Modi (scripts/)

- Modus 1 live: `live-installer.sh` (Netz+git-Check, REF-pin, clone nach
  /tmp) → `install-wizard.sh --live` (TUI, local.nix, generate-HW,
  `nix eval`-dry-build, Doppel-Confirm, `nixos-install --root /mnt`).
- Modus 2 apply: `apply.sh` (Preflight: NixOS/nicht-live/nicht-root/
  User-Match/dirty-tree → Symlinks mit `*.pre-dotfiles`-Backup (+
  Noctalia-Settings seeden wenn fehlend) → dry-build → switch).
  `install.sh` ist nur noch Shim, `bootstrap.sh` nur Checkout-Helfer.
- Modus 3 update: `update.sh [--check|--pull|--inputs]` — fetch/review/pull
  explizit, Flake-Pins bleiben bis `--inputs`. Aktiviert NIE etwas (dafuer apply).
- Modus 4 verify: `verify.sh` read-only (FAIL=fatal, warn=Hinweis).
- Auswahl liegt in `hosts/nixos/local.nix` (git-ignoriert, mkDefault-Scope);
  `settings.nix` sind Defaults. Username-Aenderung wirkt auch auf flake.nix
  (HM-User folgt local.nix). Hardware-Config NUR per `dot_with_hw_staged`
  (lib.sh: add -f + RETURN/INT/TERM-Trap + Reset) fuer Builds sichtbar machen.

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
  `dotfiles/.local/state/noctalia/settings.toml`, Installer seedet einmalig als
  beschreibbare Kopie — HM verwaltet sie NICHT, Store-Link waere read-only).
- Generierte Themes (`gtk-*/noctalia.css`, `kitty`,
  `rofi`) NICHT hand-editieren — Wallpaper-Pipeline schreibt sie neu.

## Ownership: Installer vs Home-Manager (hart gelernt)

- Installer (apply.sh, beschreibbar): `~/.config/*`, `~/.local/bin`,
  `~/.local/share/applications`, Noctalia-Seed (nur wenn fehlend).
- HM (home-entry.nix): NUR Fonts. Keine `~/.config`-Pfade (Flake-Quellen
  landen read-only im Store; Doppel-Verwaltung bricht die Aktivierung ab:
  "would be clobbered" / "conflicts with recursively symlinked file").
- Darum: `programs.fish` AUS (Repo-Link + `config.fish`), `programs.starship`
  AUS (Repo-Link + manueller Shell-Init), `programs.zsh` AN (schreibt nur
  `~/.zshrc`, kollidiert mit nichts).

## Workflows

- Edit → `alejandra` → `dry-build` (mit gestagter Hardware) → erst dann `switch`.
- Hardware für Builds: `cp /etc/nixos/hardware-configuration.nix
  hosts/nixos/ && git add -f hosts/nixos/hardware-configuration.nix`,
  danach **sofort** `git reset` + löschen (bleibt git-ignoriert).
- `system.stateVersion` nie heben. `nix.gc` 30d nicht kürzen (Rollback-Gen-Schutz).
