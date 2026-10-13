{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.lysec.tablet {
    hardware.opentabletdriver.enable = true;
    hardware.opentabletdriver.daemon.enable = true;
    environment.systemPackages = [pkgs.opentabletdriver];
  };
}
