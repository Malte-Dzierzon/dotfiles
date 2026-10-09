{config, lib, ...}: {
  # lysec.stateVersion -> system.stateVersion (einmalig gesetzt, nie heben).
  system.stateVersion = config.lysec.stateVersion;
  imports =
    [
      ../../modules/nixos/boot.nix
      ../../modules/nixos/nix.nix
      ../../modules/nixos/locale.nix
      ../../modules/nixos/networking.nix
      ../../modules/nixos/audio.nix
      ../../modules/nixos/greeter.nix
      ../../modules/nixos/user.nix
      ../../desktops/umbriel/nixos.nix
    ]
    ++ [./hardware-configuration.nix]
    # hosts/nixos/local.nix: Installer-Auswahl pro Maschine (git-ignoriert,
    # optional). Flake setzt settings.nix als mkDefault — local.nix gewinnt je Wert.
    ++ lib.optional (builtins.pathExists ./local.nix) ./local.nix;
}
