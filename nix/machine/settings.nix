{
  username = "xealom";
  hostname = "nixos";
  stateVersion = "26.05";
  system = "x86_64-linux";
  # Weak laptop: avoid heavy builds. Strong PC: set to true.
  buildFromSource = false;
  tablet = false;
  # Installer selection (install-wizard.sh --apply writes nix/machine/local.nix,
  # which overrides these values per machine — settings.nix remains the default).
  keyboardLayout = "de";
  consoleKeyMap = "de";
  profile = "laptop";
  timezone = "Europe/Berlin";
  mainLocale = "en_US.UTF-8";
  regionalLocale = "de_DE.UTF-8";
  # Fresh installs without local.nix: core only (installer asks per app).
  # Existing machines keep their local.nix selection.
  bundles = [];
  git = {
    name = "Malte Dzierzon";
    email = "malte@dzierzon.example";
    signingKey = "";
  };
}
