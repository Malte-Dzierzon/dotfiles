{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.umbriel.nixosModules.default
  ];

  # ── Boot ──
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── Nix ──
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;

  # Noctalia Binary-Cache (v5 aus Flake, kein lokales Kompilieren)
  nix.settings.extra-substituters = [
    "https://noctalia.cachix.org"
  ];
  nix.settings.extra-trusted-public-keys = [
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
  ];

  # NICHT kürzer: sonst fliegt dein Gen-54-Rollback (Mesa 26.1.8) weg
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;

  # ── Memory / Logging ──
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  services.journald.settings.Journal = {
    SystemMaxUse = "200M";
    SystemKeepFree = "1G";
  };

  # ── System ──
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  # Intel HD 610: explizit an, damit /run/opengl-driver stabil bleibt
  hardware.graphics.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };
  console.keyMap = "de";

  # ── Wayland / Compositor ──
  programs.umbriel.enable = true;
  programs.niri.enable = true;
  environment.pathsToLink = ["/share/wayland-sessions"];
  services.desktopManager.gnome.enable = false;
  services.displayManager.gdm.enable = false;

  # ── Noctalia Greeter ──
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    home = "/var/lib/noctalia-greeter";
    createHome = false;
  };
  users.groups.greeter = {};
  systemd.tmpfiles.settings."10-noctalia-greeter" = {
    "/var/lib/noctalia-greeter".d = {
      user = "greeter";
      group = "greeter";
      mode = "0750";
    };
  };
  systemd.tmpfiles.rules = [
    "L+ /var/lib/noctalia-greeter/greeter.toml - - - - /etc/noctalia-greeter/greeter.toml"
  ];
  environment.etc."noctalia-greeter/greeter.toml".text = ''
    [session]
    default = "Umbriel"
    [user]
    default = "xealom"
    [keyboard]
    layout = "de"
    [appearance]
    corner_radius_scale = 0.0
    font_family = "JetBrainsMono NFM"
  '';
  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
      command = lib.mkDefault "${pkgs.noctalia-greeter}/bin/noctalia-greeter-session";
    };
  };
  services.accounts-daemon.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.noctalia.greeter.sync-appearance" &&
          action.lookup("program") == "${pkgs.noctalia-greeter}/bin/noctalia-greeter-apply-appearance" &&
          action.lookup("user") == "root" &&
          subject.local &&
          subject.active &&
          subject.user == "xealom") {
        return polkit.Result.YES;
      }
    });
  '';
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

  # ── Permissions ──
  security.sudo.extraRules = [
    {
      users = ["xealom"];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/nh";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # ── Audio ──
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;

  # ── XDG Portal ──
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  # ── Environment ──
  environment.variables = {
    QT_QPA_PLATFORM = "wayland";
    GTK_IM_MODULE = "";
    QT_IM_MODULE = "";
    EDITOR = "zeditor --wait";
    VISUAL = "zeditor --wait";
  };

  # ── Printing ──
  services.printing.enable = true;

  # ── Fonts ──
  fonts.packages = with pkgs; [
    jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    material-symbols
  ];

  # ── User ──
  users.users.xealom = {
    isNormalUser = true;
    description = "xealom";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
  };
  users.defaultUserShell = pkgs.zsh;

  # ── Shell / CLI ──
  programs.firefox.enable = false;
  programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.neovim = {
    enable = true;
    defaultEditor = false;
  };

  # ── Flatpak ──
  services.flatpak.enable = true;
  systemd.services.flatpak-serein = {
    description = "Ensure Serein flatpak is installed";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    path = with pkgs; [flatpak];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      flatpak install -y --noninteractive flathub cz.viceverse.serein || true
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # ── Packages ──
  environment.systemPackages = with pkgs;
    [
      # Desktop / GUI
      walker
      nautilus
      file-roller
      foot
      wlsunset

      # Development
      zed-editor
      git
      gcc
      gh
      lazygit
      lazydocker
      jq
      nodejs
      python3
      nix-search-tv
      pi-coding-agent
      nil
      alejandra
      nh

      # Shell
      tmux
      starship
      eza
      fzf
      zoxide
      bat
      fd
      ripgrep
      fastfetch
      yazi
      btop
      gdu
      tree
      zip
      unzip
      file
      wget
      psmisc

      # Audio / Media
      mpd
      mpc
      rmpc
      wiremix
      playerctl
      brightnessctl
      imv
      chafa
      mpv
      ffmpeg

      # Wayland
      wl-clipboard
      libnotify
      polkit_gnome
      grim
      slurp
      xdg-utils
      appimage-run

      # Apps
      obsidian
      readest
      bitwarden-cli
      flare-signal
      prismlauncher
      osu-lazer-bin
      noctalia-greeter
      lmstudio
      inkscape

      # Security / Network
      nmap
      bluez
      iw
    ]
    ++ (with inputs; [
      zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      concord.packages.${pkgs.stdenv.hostPlatform.system}.default
      toofan.packages.${pkgs.stdenv.hostPlatform.system}.default
      sonora.packages.${pkgs.stdenv.hostPlatform.system}.sonora-bin
      noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]);

  # ── Polkit authentication agent ──
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome authentication agent";
    wantedBy = ["graphical-session.target"];
    wants = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  documentation.nixos.enable = false;
  system.stateVersion = "26.05";
}
