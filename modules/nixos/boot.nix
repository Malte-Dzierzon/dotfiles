{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Acer Spin SP314-51: intel_vbtn meldet Tablet-Modus -> Keyboard+Touchpad tot
  boot.blacklistedKernelModules = [ "intel_vbtn" ];
}
