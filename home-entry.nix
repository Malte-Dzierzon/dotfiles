# Home-Manager-Entrypoint: User-Identitaet + Programme + Desktop-Profil + dotfile-Symlinks.
{ osConfig, config, desktop, ... }:

let
  desktopHome =
    if desktop == "hyprland" then ./desktops/hyprland/home.nix
    else if desktop == "mango" then ./desktops/mango/home.nix
    else ./desktops/niri/home.nix;
  dot = ./configs/dotconfig;
  # Verzeichnisse als beschreibbare Links (Noctalia schreibt Theme-Dateien neu).
  dirs = builtins.filter (d: d != "mimeapps.list" && d != "starship")
    (builtins.attrNames (builtins.readDir dot));
  link = d: {
    name = ".config/${d}";
    value = { source = config.lib.file.mkOutOfStoreSymlink "${dot}/${d}"; };
  };
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

  home.file = builtins.listToAttrs (map link dirs) // {
    ".config/starship.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${dot}/starship/starship.toml";
    ".config/mimeapps.list".source =
      config.lib.file.mkOutOfStoreSymlink "${dot}/mimeapps.list";
    ".local/bin".source = ./home/.local/bin;
    ".local/bin".recursive = true;
    ".local/share/applications".source = ./home/.local/share/applications;
    ".local/share/applications".recursive = true;
  };
}
