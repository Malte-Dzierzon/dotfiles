# Home-Manager-Entrypoint: User-Identitaet + Programme + Desktop-Profil + Fonts.
#
# Ownership (hart gelernt): ~/.config/*, ~/.local/bin und
# ~/.local/share/applications gehoeren dem INSTALLER (scripts/apply.sh,
# beschreibbare Links ins Live-Repo — Noctalia schreibt Theme-Dateien
# zurueck). HM darf diese Pfade NICHT deklarieren: Flake-relative Quellen
# landen im Store (read-only) und jede Doppel-Verwaltung bricht die
# Aktivierung ab ("would be clobbered" / "conflicts with recursively
# symlinked file"). Gleiches gilt fuer Noctalia-Live-Settings (HM-Link
# waere read-only, Noctalia kann nicht zurueckschreiben — Installer seedet
# einmalig, danach unversioniert) sowie programs.fish/starship (schreiben
# nach ~/.config/fish bzw. starship.toml — Repo-Links + manueller Init
# stattdessen, siehe home/shell/).
{osConfig, ...}: {
  imports = [
    ./home/default.nix
    ./desktops/umbriel/home.nix
  ];

  home.username = osConfig.lysec.username;
  home.homeDirectory = "/home/${osConfig.lysec.username}";
  home.stateVersion = osConfig.lysec.stateVersion;
  programs.home-manager.enable = true;

  home.file = {
    # Fonts: read-only Store-Links sind ok (niemand schreibt hierher).
    ".local/share/fonts".source = ./home/.local/share/fonts;
    ".local/share/fonts".recursive = true;
  };
}
