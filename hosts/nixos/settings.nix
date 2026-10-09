{
  username = "xealom";
  hostname = "nixos";
  stateVersion = "26.05";
  system = "x86_64-linux";
  # Schwacher Laptop: schwere Builds vermeiden. Starker PC: true setzen.
  buildFromSource = false;
  # Installer-Auswahl (scripts/live-installer.sh schreibt hosts/nixos/local.nix,
  # das diese Werte pro Maschine ueberschreibt — settings.nix bleibt Default).
  keyboardLayout = "de";
  consoleKeyMap = "de";
  profile = "laptop";
  timezone = "Europe/Berlin";
  mainLocale = "en_US.UTF-8";
  regionalLocale = "de_DE.UTF-8";
  bundles = [
    "core"
    "terminal"
    "editor"
    "desktop"
    "browser"
    "dev"
    "latex"
    "notes"
    "media"
    "gaming"
    "chat"
    "net"
    "fun"
  ];
  git = {
    name = "Malte Dzierzon";
    email = "malte@dzierzon.example";
    signingKey = "";
  };
}
