{config, ...}: {
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
    ++ [./hardware-configuration.nix];
}
