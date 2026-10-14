{pkgs, ...}: {
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  # Intel HD 610: explicitly on, so /run/opengl-driver stays stable
  hardware.graphics.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  services.flatpak.enable = true;
  systemd.services.flatpak-serein = {
    description = "Ensure Serein flatpak is installed";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    path = with pkgs; [flatpak];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      flatpak remote-add --if-not-exists serein-origin https://viceverse-cz.github.io/Serein/flatpak/repo
      flatpak install -y --noninteractive serein-origin cz.viceverse.serein || true
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
