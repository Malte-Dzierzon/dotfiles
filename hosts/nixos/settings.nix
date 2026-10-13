{
  username = "xealom";
  hostname = "nixos";
  stateVersion = "26.05";
  system = "x86_64-linux";
  # Weak laptop: avoid heavy builds. Strong PC: set to true.
  buildFromSource = false;
  tablet = false;
  # Installer selection (install-wizard.sh --apply writes hosts/nixos/local.nix,
  # which overrides these values per machine — settings.nix remains the default).
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
    "godot"
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
