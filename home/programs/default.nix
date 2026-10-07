{
  pkgs,
  inputs,
  osConfig,
  lib,
  ...
}: let
  # Schwache Maschine: schwere Pakete NICHT aus Nix bauen (dauert ewig),
  # stattdessen AppImage/Binary per install.sh. Starker PC: alles aus Nix.
  fromSource = osConfig.lysec.buildFromSource;
in {
  home.packages = with pkgs;
    [
      inputs.toofan.packages.${stdenv.hostPlatform.system}.default
      # Terminals (alle Noctalia-thematisiert, Config in configs/dotconfig)
      foot
      kitty
      alacritty
      ghostty
      # Basis / Desktop
      walker
      zed-editor
      nautilus
      file-roller
      zip
      tmux
      starship
      eza
      fzf
      zoxide
      bat
      fd
      ripgrep
      fastfetch
      brightnessctl
      noctalia-greeter
      btop
      cava
      git
      tree
      unzip
      file
      wget
      psmisc
      rofi
      adwaita-icon-theme
      yaru-theme
      # Entwicklung / Git (toofan: Flake-Input, s. flake.nix)
      gh
      lazygit
      lazydocker
      neovim
      # Medien (mpd + mpc + rmpc gehoeren zusammen)
      kew
      imv
      chafa
      wiremix
      playerctl
      mpv
      mpd
      mpc
      rmpc
      readest
      # Utilities (qalculate-qt: GUI-Rechner, noctalia.conf via qt6ct)
      libqalculate
      qalculate-qt
      gdu
      bitwarden-cli
      python3
      nix-search-tv
      ffmpeg
      appimage-run
      nmap
      wireshark
      bluez
      iw
      xdg-utils
      obsidian
      qt6Packages.qt6ct
      # Wayland
      wlsunset
      swaylock # niri-Bind Mod+Alt+L
      grim
      slurp
      xwayland-satellite
      polkit_gnome
      (yazi.override {_7zz = _7zz-rar;})
      nodejs
      zettlr
      pi-coding-agent
      # Browser deklarativ aus dem gepinnten Flake-Input (statt nix profile install).
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      # Gaming / Launcher
      prismlauncher
      steam-run
      # Chat / Calls (user scope, kein Systemdienst)
      inputs.concord.packages.${stdenv.hostPlatform.system}.default
      inputs.sonora.packages.${stdenv.hostPlatform.system}.sonora-bin
      flare-signal
      # Spiele-Binary (AppImage, ausserhalb nixpkgs)
      osu-lazer-bin
      inkscape
      # Noctalia-Shell deklarativ aus dem Flake-Input (statt ~/.local/bin-Symlink auf /nix/store).
      inputs.noctalia
    ]
    # Schwere Builds nur auf starker Maschine; schwacher Laptop nutzt AppImages (install.sh).
    ++ (lib.optionals fromSource [lmstudio]);
}
