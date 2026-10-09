{osConfig, ...}: {
  # fish gehoert dem INSTALLER (~/.config/fish als beschreibbarer Repo-Link).
  # HM-Modul bleibt AUS: es wuerde ~/.config/fish/config.fish generieren und
  # damit bauen ("conflicts with recursively symlinked file", Config wird
  # still verworfen). Repo-config versorgt Prompt + Env (siehe
  # configs/dotconfig/fish/config.fish).
  programs.fish.enable = false;
  # Git-Identitaet aus hosts/nixos/settings.nix (lysec.git).
  programs.git = {
    enable = true;
    settings.user.name = osConfig.lysec.git.name;
    settings.user.email = osConfig.lysec.git.email;
    # signingKey leer (Default) -> kein Signieren; gesetzt -> commit.gpgsign an.
    settings.user.signingkey = osConfig.lysec.git.signingKey;
    settings.commit.gpgsign = osConfig.lysec.git.signingKey != "";
  };
  # starship OHNE HM-Modul: Binary kommt aus dem core-Bundle, Config als
  # Repo-Link (configs/dotconfig/starship/starship.toml, Noctalia schreibt
  # Palette zurueck). Das Modul wuerde starship.toml generieren -> Kollision.
  # Init je Shell manuell (fish: config.fish, zsh: unten).
  # Login-Shell ist zsh (modules/nixos/user.nix) — fish bleibt als interaktive
  # Alternative mit identischen Defaults (Repo = Wahrheit fuer beide).
  programs.zsh = {
    enable = true;
    initContent = ''
      export EDITOR="zeditor --wait"
      export VISUAL="zeditor --wait"
      export SUDO_EDITOR="zeditor --wait"
      export GIT_EDITOR="zeditor --wait"
      export BROWSER=zen
      export TERMINAL=foot
      export PATH="$HOME/.local/bin:$PATH"
      command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
      command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
    '';
  };
  # mpd als User-Service (paired mit configs/dotconfig/mpd/mpd.conf + rmpc).
  services.mpd = {
    enable = true;
    musicDirectory = "~/Music";
  };
}
