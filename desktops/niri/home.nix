{ ... }:
{
  imports = [ ../shared/home.nix ];
  # niri config kommt aus configs/niri (home.file-Verlinkung in home/default.nix)
  home.packages = [ ];
}
