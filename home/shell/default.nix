{osConfig, ...}: {
  programs.fish.enable = true;
  # Git-Identitaet aus hosts/nixos/settings.nix (lysec.git).
  programs.git = {
    enable = true;
    settings.user.name = osConfig.lysec.git.name;
    settings.user.email = osConfig.lysec.git.email;
  };
  # starship-Konfiguration liegt in configs/dotconfig/starship/starship.toml
  # (inkl. Noctalia-Palette). HM verwaltet nur das Binary + Integration.
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
  # mpd als User-Service (paired mit configs/dotconfig/mpd/mpd.conf + rmpc).
  services.mpd = {
    enable = true;
    musicDirectory = "~/Music";
  };
}
