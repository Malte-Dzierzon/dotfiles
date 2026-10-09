{
  config,
  lib,
  pkgs,
  ...
}: let
  xpPen = pkgs.callPackage ../../pkgs/xp-pen-tablet {};
in {
  options.lysec.tablet = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable XP-Pen tablet driver (udev rules + PenTablet UI package).";
  };

  config = lib.mkIf config.lysec.tablet {
    # uaccess grants the logged-in user device access; rules ship in the
    # package output (lib/udev/rules.d) like the AUR package does.
    services.udev.packages = [xpPen];
    environment.systemPackages = [xpPen];
  };
}
