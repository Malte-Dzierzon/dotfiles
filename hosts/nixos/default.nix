{ lib, desktop, ... }:
let
  desktopNixos =
    if desktop == "umbriel" then ../../desktops/umbriel/nixos.nix
    else if desktop == "hyprland" then ../../desktops/hyprland/nixos.nix
    else if desktop == "mango" then ../../desktops/mango/nixos.nix
    else ../../desktops/niri/nixos.nix;
in
{
  imports = [
    ../../modules/nixos/boot.nix
    ../../modules/nixos/nix.nix
    ../../modules/nixos/locale.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/greeter.nix
    ../../modules/nixos/user.nix
    desktopNixos
  ]
  ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;
}
