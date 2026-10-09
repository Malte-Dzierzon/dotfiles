{
  pkgs,
  config,
  lib,
  ...
}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Acer Spin SP314-51: intel_vbtn meldet Tablet-Modus -> Keyboard+Touchpad tot.
  # Nur Laptop-Profil; Desktops bekommen den Quirk nie (lysec.profile).
  boot.blacklistedKernelModules = lib.optionals (config.lysec.profile == "laptop") ["intel_vbtn"];
  # XP-Pen driver creates virtual pen devices via /dev/uinput.
  boot.kernelModules = ["uinput"];
}
