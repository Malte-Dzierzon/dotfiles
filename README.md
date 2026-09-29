# dotfiles (niri + Noctalia, NixOS 26.05)

Struktur nach [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) (`standard`):
Flake + `hosts/<hostname>/` (System) + `home/` (Home-Manager = User-Symlinks + User-Pakete).

```
dotfiles/
├── flake.nix                 # nixosConfigurations.nixos (26.05 + home-manager)
├── hosts/nixos/              # configuration.nix + hardware-configuration.nix (host-lokal, gitignored)
│   └── hardware-configuration.nix.example
├── home/
│   ├── xealom.nix            # home-manager: verlinkt .config/.local, user-pakete (node, zettlr)
│   ├── .config/{niri,hypr,mango,noctalia,fish}/…
│   └── .local/{bin,share/applications}/…
└── scripts/
    ├── bootstrap.sh          # Ein-Zeiler für frische Systeme
    └── install.sh            # Auto-Install (nix → symlinks → rebuild → user-pkgs)
```

## Neu einrichten (frisches NixOS)

```bash
curl -fsSL https://raw.githubusercontent.com/Malte-Dzierzon/dotfiles/main/scripts/bootstrap.sh | bash
```

Das macht: nix-Flakes prüfen → Repo nach `~/Projects/dotfiles` klonen →
Home-Configs verlinken → Hardware-Config übernehmen →
`sudo nixos-rebuild switch --flake ~/Projects/dotfiles#nixos` →
Zen-Browser als User-Paket.

## Wiederherstellen (Repo schon da)

```bash
git clone git@github.com:Malte-Dzierzon/dotfiles.git ~/Projects/dotfiles
~/Projects/dotfiles/scripts/install.sh        # alles
~/Projects/dotfiles/scripts/install.sh --no-rebuild --no-user-pkgs  # nur symlinks
```

## Alltag

```bash
sudo nixos-rebuild switch --flake ~/Projects/dotfiles#nixos   # System+Home anwenden
nix flake update ~/Projects/dotfiles                          # Kanäle updaten
```

Zettlr-Desktop: `Exec=zettlr --no-sandbox %U`.
