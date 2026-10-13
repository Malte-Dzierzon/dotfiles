# AGENTS.md

Source of truth for this repo's architecture. Short on purpose.

## What this repo is

NixOS setup (Umbriel + Noctalia). Clone onto installed NixOS, run
`./scripts/apply.sh` (or `dot apply` once linked). No Live-ISO flow.

## Ownership (hard boundary)

- **apply.sh owns (writable):** `~/.config/*`, `~/.local/bin`,
  `~/.local/share/applications`, Noctalia seed (once, if missing).
- **Home-Manager owns:** fonts only (`home-entry.nix`). No `~/.config`
  paths — store links are read-only and clash with installer symlinks.
- Consequence: `programs.fish`/`starship` OFF (repo link wins),
  `programs.zsh` ON (writes only `~/.zshrc`).

## Machine-local vs shared

- `hosts/nixos/settings.nix` = committed defaults.
- `hosts/nixos/local.nix` = per-machine overrides (bundles, user, tablet,
  buildFromSource). **Git-ignored, never commit.**
- `hosts/nixos/hardware-configuration.nix` = generated on the machine,
  **git-ignored**. Visible to builds via the `path:` snapshot
  (`dot_snapshot` in `lib.sh`)
  (force-add + trap reset, never leaks UUIDs).
- Noctalia live settings (`~/.local/state/noctalia/`) stay local.

## Scripts (one job each)

| Script | Job |
|---|---|
| `scripts/dot` | minimal CLI: menu, ls, apps, check, apply, restore, help |
| `apply.sh` | link configs (+backup) → snapshot build → confirm → switch → verify |
| `check.sh` | fast static checks; `--full` adds flake eval + dry build. No writes |
| `install.sh` | staged entry: env checks → wizard → apply. User only, no root |
| `install-wizard.sh --apply` | TUI writing `local.nix`, then execs apply |
| `apps.sh` | bundle selection from catalog → writes `local.nix`, no activation |
| `mime.sh` | compare roles vs mimeapps.list, `--fix` aligns with backup |
| `applist.sh` | inventory: installed apps + source. No install/select logic |
| `verify.sh` | read-only health check. Changes nothing |
| `mode.sh` | desktop/headless target helper (kept, not core `dot`) |

Removed: `sync.sh`, `save.sh`, `restore.sh` (custom git workflows —
use plain `git`), old `install.sh` shim, `live-installer.sh`,
`bootstrap.sh`, old `update.sh`. If a reference resurfaces, delete it.

## Catalog & selection

- `home/programs/bundles.nix` = single catalog (names + blurbs + resolve).
  Never a second list. `apps.sh` reads names via `nix eval`.
- Selection unit = **bundle**. Stored as `lysec.bundles` in `local.nix`.
- `lysec` = project option namespace (user, host, locale, bundles, …).
  Declared in `modules/lysec/options.nix`, filled from `settings.nix`
  (defaults) + `local.nix` (per-machine) via `flake.nix`.
- Heavy builds gated by `lysec.buildFromSource` in
  `home/programs/default.nix` (rule: build > 10 min on laptop → gate).
- GUI-installed apps: `apply.sh` links their configs anyway; missing
  binaries are warn-only, never fatal.

## Desktop config (native Umbriel includes, no generator)

- `dotfiles/.config/umbriel/config.toml` = load order only.
- Partials: `bindings` (keys via `default-app`), `input`, `look`,
  `monitors`, `autostart`, `env`. Validate: `dot check`.
- `config/defaults.toml` = six roles (terminal/editor/browser/file/pdf/notes).
  `default-app --set` changes one; TUI editors wrap in terminal automatically.
  MIME lives in `mimeapps.list`; align with `dot mime --fix`.
- Installed apps: single source `home/programs/bundles.nix` (catalog), selected via `lysec.bundles` in `local.nix` (`dot apps`). `config/` holds only app *roles*.

## Safety rules

- Symlinks: real files → `*.pre-dotfiles`, never overwrite; dangling
  links replaced with warning; existing backup = abort.
- `apply.sh` preflights (NixOS, user match, deps) run
  before any mutation. Snapshot build + confirm always precede switch.
- Secrets: never commit tokens/keys. `verify.sh` scans 5 patterns.
- `system.stateVersion` never bump.

## Workflows

- Edit config → `dot check` → `dot apply` (no commit needed).
- Role change → `default-app --set <role> <bin>` → `dot mime` → check → apply.
- Catalog change → edit `bundles.nix` → `dot apps` to reselect → apply.
- Rollback → `dot restore` (generations; source files need file backups).
- Git → plain `git` (no wrapper). Hardware/local files stay git-ignored.
