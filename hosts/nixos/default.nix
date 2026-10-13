{
  config,
  lib,
  ...
}: {
  # lysec.stateVersion -> system.stateVersion (set once, never raise).
  system.stateVersion = config.lysec.stateVersion;
  imports =
    [
      ../../modules/nixos/boot.nix
      ../../desktops/umbriel/nixos.nix
      ../../modules/nixos/nix.nix
      ../../modules/nixos/locale.nix
      ../../modules/nixos/networking.nix
      ../../modules/nixos/audio.nix
      ../../modules/nixos/greeter.nix
      ../../modules/nixos/user.nix
      ../../modules/nixos/tablet.nix
      ../../modules/nixos/remote.nix
    ]
    ++ [./hardware-configuration.nix]
    # hosts/nixos/local.nix: per-machine installer selection (git-ignored,
    # optional). The flake sets settings.nix as mkDefault — local.nix wins per value.
    ++ lib.optional (builtins.pathExists ./local.nix) ./local.nix;
}
