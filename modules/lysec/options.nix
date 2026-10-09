{lib, ...}: {
  options.lysec = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "Primary user account name.";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "Networking hostname.";
    };
    stateVersion = lib.mkOption {
      type = lib.types.str;
      description = "NixOS / home-manager stateVersion";
    };
    system = lib.mkOption {
      type = lib.types.str;
      description = "Nixpkgs system string";
    };
    buildFromSource = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Schwache Maschine (false): schwere Pakete als AppImage/Binary statt Nix-Build. Starke Maschine (true): alles aus Nix bauen.";
    };
    git = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Git user.name";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Git user.email";
      };
      signingKey = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "OpenPGP signing key id";
      };
    };
  };
}
