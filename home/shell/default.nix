{osConfig, ...}: {
  programs.fish.enable = true;
  # Git-Identitaet aus hosts/nixos/settings.nix (lysec.git).
  programs.git = {
    enable = true;
    settings.user.name = osConfig.lysec.git.name;
    settings.user.email = osConfig.lysec.git.email;
    # signingKey leer (Default) -> kein Signieren; gesetzt -> commit.gpgsign an.
    settings.user.signingkey = osConfig.lysec.git.signingKey;
    settings.commit.gpgsign = osConfig.lysec.git.signingKey != "";
  };
  # starship-Konfiguration liegt in configs/dotconfig/starship/starship.toml
  # (inkl. Noctalia-Palette). HM verwaltet nur das Binary + Integration.
  # Login-Shell ist zsh (modules/nixos/user.nix) — fish bleibt als interaktive
  # Alternative mit identischen Defaults (Repo = Wahrheit fuer beide).
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };
  programs.zsh = {
    enable = true;
    initExtra = ''
      export EDITOR="zeditor --wait"
      export VISUAL="zeditor --wait"
      export SUDO_EDITOR="zeditor --wait"
      export GIT_EDITOR="zeditor --wait"
      export BROWSER=zen
      export TERMINAL=foot
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };
  # mpd als User-Service (paired mit configs/dotconfig/mpd/mpd.conf + rmpc).
  services.mpd = {
    enable = true;
    musicDirectory = "~/Music";
  };
}
