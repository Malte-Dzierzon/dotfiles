{
  config,
  lib,
  ...
}: {
  # lysec.stateVersion -> system.stateVersion (set once, never raise).
  system.stateVersion = config.lysec.stateVersion;
  imports =
    [
      ./boot.nix
      ../desktop/umbriel/nixos.nix
      ./nix.nix
      ./locale.nix
      ./networking.nix
      ./audio.nix
      ./greeter.nix
      ./user.nix
      ./tablet.nix
      ./remote.nix
    ]
    ++ [../machine/hardware-configuration.nix]
    # nix/machine/local.nix: per-machine installer selection (git-ignored,
    # optional). The flake sets settings.nix as mkDefault — local.nix wins per value.
    ++ lib.optional (builtins.pathExists ../machine/local.nix) ../machine/local.nix;
}
