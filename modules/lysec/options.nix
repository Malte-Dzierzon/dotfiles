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
      default = false;
      description = "Schwache Maschine (false): schwere Pakete als AppImage/Binary statt Nix-Build. Starke Maschine (true): alles aus Nix bauen.";
    };
    keyboardLayout = lib.mkOption {
      type = lib.types.str;
      default = "de";
      description = "Physical keyboard: XKB layout name (de, us, gb, or any xkbcli layout). Umbriel follows the system layout automatically; the greeter follows this XKB value.";
    };
    consoleKeyMap = lib.mkOption {
      type = lib.types.str;
      default = "de";
      description = "Linux console keymap. The installer derives it from keyboardLayout (gb -> uk); override only if you know the console name differs.";
    };
    profile = lib.mkOption {
      type = lib.types.enum ["laptop" "desktop"];
      default = "laptop";
      description = "Machine profile: laptop enables portable-only quirks (e.g. intel_vbtn blacklist); desktop skips them. Never replaces hardware-configuration.nix.";
    };
    timezone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Berlin";
      description = "System timezone (IANA name).";
    };
    mainLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "i18n.defaultLocale.";
    };
    regionalLocale = lib.mkOption {
      type = lib.types.str;
      default = "de_DE.UTF-8";
      description = "LC_* bundle (address, time, paper, ...).";
    };
    bundles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
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
      description = "Selected application bundles (see home/programs/bundles.nix). Unknown names fail the build with the valid list.";
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
