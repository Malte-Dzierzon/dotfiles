# dotfiles (niri + Noctalia, NixOS 26.05)

## Wiederherstellen
```bash
git clone git@github.com:Malte-Dzierzon/dotfiles.git ~/Projects/dotfiles
./scripts/install.sh
sudo cp nixos/configuration.nix /etc/nixos/configuration.nix
sudo nixos-generate-config --show-hardware-config > /tmp/hw && diff /tmp/hw nixos/hardware-configuration.nix.example
sudo nixos-rebuild switch
nix profile install github:youwen5/zen-browser-flake
nix profile install nixpkgs#zettlr
```
Zettlr-Desktop: `Exec=zettlr --no-sandbox %U`.
