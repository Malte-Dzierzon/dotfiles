{ pkgs, ... }:
{
  home.username = "xealom";
  home.homeDirectory = "/home/xealom";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  # alles unter ../.config + bin + desktop-files als Symlinks
  home.file =
    let
      dot = ../.config;
      dirs = builtins.attrNames (builtins.readDir dot);
    in
    builtins.listToAttrs (map (d: {
      name = ".config/${d}";
      value = {
        source = dot + "/${d}";
        recursive = true;
      };
    }) dirs)
    // {
      ".local/bin".source = ../.local/bin;
      ".local/bin".recursive = true;
      ".local/share/applications".source = ../.local/share/applications;
      ".local/share/applications".recursive = true;
    };

  # User-Profil: alles was nicht systemweit muss
  home.packages = with pkgs; [
    nodejs
    zettlr
  ];

  programs.zen-browser = {
    enable = false; # flake noch nicht verdrahtet, install.sh pinnt per `nix profile`
  };
}
