{ ... }:
{
  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
}
