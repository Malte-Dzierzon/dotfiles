# Home-Manager-Entrypoint: User-Identitaet + Programme + Desktop-Profil + dotfile-Symlinks.
{ osConfig, desktop, ... }:
let
  desktopHome =
    if desktop == "hyprland" then ./desktops/hyprland/home.nix
    else if desktop == "mango" then ./desktops/mango/home.nix
    else ./desktops/niri/home.nix;
  dot = ./configs/dotconfig;
  dirs = builtins.attrNames (builtins.readDir dot);
in
{
  imports = [
    ./home/default.nix
    desktopHome
  ];

  home.username = osConfig.lysec.username;
  home.homeDirectory = "/home/${osConfig.lysec.username}";
  home.stateVersion = osConfig.lysec.stateVersion;
  programs.home-manager.enable = true;

  home.file = builtins.listToAttrs (map (d: {
    name = ".config/${d}";
    value = { source = dot + "/${d}"; recursive = true; };
  }) dirs) // {
    ".local/bin".source = ./home/.local/bin;
    ".local/bin".recursive = true;
    ".local/share/applications".source = ./home/.local/share/applications;
    ".local/share/applications".recursive = true;
  };
}
