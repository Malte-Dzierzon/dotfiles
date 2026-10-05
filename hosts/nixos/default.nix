{desktop, ...}: let
  desktopNixos =
    if desktop == "umbriel"
    then ../../desktops/umbriel/nixos.nix
    else ../../desktops/niri/nixos.nix;
in {
  imports =
    [
      ../../modules/nixos/boot.nix
      ../../modules/nixos/nix.nix
      ../../modules/nixos/locale.nix
      ../../modules/nixos/networking.nix
      ../../modules/nixos/audio.nix
      ../../modules/nixos/greeter.nix
      ../../modules/nixos/user.nix
      desktopNixos
    ]
    ++ [./hardware-configuration.nix];
}
