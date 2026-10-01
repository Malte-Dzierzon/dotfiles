{ ... }:
{
  programs.fish.enable = true;
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
