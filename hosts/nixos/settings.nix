{
  username = "xealom";
  hostname = "nixos";
  stateVersion = "26.05";
  system = "x86_64-linux";
  # Schwacher Laptop: schwere Builds vermeiden. Starker PC: true setzen.
  buildFromSource = false;
  git = {
    name = "Malte Dzierzon";
    email = "malte@dzierzon.example";
    signingKey = "";
  };
}
