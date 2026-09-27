{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [./hardware-configuration.nix];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix.settings.experimental-features = ["nix-command" "flakes"];
  programs.nix-ld.enable = true;
  nixpkgs.config.allowUnfree = true;
  # Store wächst sonst unbegrenzt (36G, 14072 tote Pfade am 2026-09-24)
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  # 3.7 GiB RAM: komprimiertes RAM-Swap vor Disk-Swap (swappiness bleibt 60)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  # Journal war 107M ungedeckelt
  services.journald.extraConfig = ''
    SystemMaxUse=200M
    SystemKeepFree=1G
  '';

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  # bluetoothctl / bluetuith / network-toolkit brauchen das
  hardware.bluetooth.enable = true;
  # UPower + Power-Profiles: Noctalia Power/Batterie-Tab braucht org.freedesktop.UPower
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  # Mod+Shift+D (lazydocker) startet den Daemon per Socket-On-Demand (idle ~47 MiB gespart)
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;

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

  services.displayManager.gdm.enable = false;
  services.desktopManager.gnome.enable = false;

  # Flow: Laptop -> niri (Default), PC -> MangoWM (Session-Menü im Login)
  environment.pathsToLink = ["/share/wayland-sessions"];

  services.displayManager.sessionPackages = [
    pkgs.niri
    pkgs.mangowc
  ];

  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    home = "/var/lib/noctalia-greeter";
    createHome = false;
  };
  users.groups.greeter = {};
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
      };
    };
  };
  # Noctalia-Greeter: Login-Screen mit Noctalia-Wallpaper/Palette/Fonts,
  # Session-Picker (Niri/Mango), eckig passend zu Niri/Noctalia.
  # Sync Wallpaper+Farben nach Aenderung: als xealom ohne sudo moeglich.
  # Noctalia-Greeter 1.3.1: Modul existiert erst in unstable, daher manuell
  # (Funktionen aus nixos/modules/services/display-managers/noctalia-greeter.nix):
  # tmpfiles-Dir + greeter.toml + greetd-Anbindung + Polkit-Sync-Regel.
  systemd.tmpfiles.settings."10-noctalia-greeter" = {
    "/var/lib/noctalia-greeter".d = {
      user = "greeter";
      group = "greeter";
      mode = "0750";
    };
  };
  environment.etc."noctalia-greeter/greeter.toml".text = ''
    [keyboard]
    layout = "de"
    [appearance]
    corner_radius_scale = 0.0
    font_family = "JetBrainsMono NFM"
  '';
  systemd.tmpfiles.rules = [
    "L+ /var/lib/noctalia-greeter/greeter.toml - - - - /etc/noctalia-greeter/greeter.toml"
  ];
  services.greetd.settings.default_session.command = lib.mkDefault "${pkgs.noctalia-greeter}/bin/noctalia-greeter-session";
  services.accounts-daemon.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.noctalia.greeter.sync-appearance" &&
          action.lookup("program") == "${pkgs.noctalia-greeter}/bin/noctalia-greeter-apply-appearance" &&
          action.lookup("user") == "root" &&
          subject.local && subject.active && subject.user == "xealom") {
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

  # (regreet entfernt 2026-09-26: ersetzt durch Noctalia-Greeter)

  environment.etc."wayland-sessions/mango.desktop".text = ''
    [Desktop Entry]
    Name=Mango
    Comment=Mango WM
    Exec=/run/current-system/sw/bin/mango
    Type=Application
    DesktopNames=mango;wlroots
  '';

  programs.niri.enable = true;
  security.pam.services.swaylock = {};

  # sudo ohne Passwort nur für rebuild/nh (kein NOPASSWD: ALL)
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

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config.common = {
      default = ["gnome" "gtk"];
      "org.freedesktop.impl.portal.ScreenCast" = "gnome";
      "org.freedesktop.impl.portal.Screenshot" = "gnome";
      "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal
      # xdg-desktop-portal-gtk  # RAM-Opt 2026-09-24: gnome-Portal deckt GTK ab
      xdg-desktop-portal-gnome
      # Screensharing unter Mango (Niri nutzt weiter gnome)
      xdg-desktop-portal-wlr
    ];
  };
  environment.variables = {
    QT_QPA_PLATFORM = "wayland";
    GTK_IM_MODULE = "";
    QT_IM_MODULE = "";
    # Binary heißt `zeditor`, `zed` gibt es nicht
    EDITOR = "zeditor --wait";
    VISUAL = "zeditor --wait";
  };

  services.printing.enable = true;

  fonts.packages = with pkgs; [
    jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts._0xproto
    nerd-fonts.droid-sans-mono
    nerd-fonts.jetbrains-mono
    material-symbols
  ];

  users.users."xealom" = {
    isNormalUser = true;
    description = "xealom";
    shell = pkgs.zsh;
    extraGroups = ["networkmanager" "wheel" "docker"];
  };
  users.defaultUserShell = pkgs.zsh;

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

  environment.systemPackages = with pkgs; [
    # Basis / Desktop
    # xwayland-satellite  # RAM-Opt 2026-09-24: niri startet on-demand
    # kitty  # RAM-Opt 2026-09-24: foot ist Standard
    walker
    # Binary heißt `zeditor`, nicht `zed`
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
    git
    nh
    alejandra
    nil
    jq
    tree
    unzip
    file
    wget
    # fuser, killall, pstree (u.a. bitwarden-Docs, nix-monitor)
    psmisc
    # pi + nodejs RAUS: neuer im User-Profil (nix profile)
    # zen-browser per-user via zen-browser-flake, nicht hier

    # Entwicklung / Git
    gh
    lazygit
    # Mod+Shift+D; braucht den Docker-Daemon (oben an)
    lazydocker

    # Datei-/Terminal-Tools
    # `y`-Wrapper in fish/config.fish war ohne Binary tot
    # yazi  # RAM-Opt 2026-09-24: raus

    # Medien
    # Mod+Alt+M zeigt hierhin (`cliamp` gab es nicht)
    kew
    imv
    chafa

    # Audio
    wiremix
    # Niri-Medientasten, sonst tote Binds
    playerctl

    # Clipboard
    # liefert wl-copy/wl-paste
    wl-clipboard
    # clipse  # RAM-Opt 2026-09-24: raus

    # Utilities
    # liefert `qalc`
    libqalculate
    gdu

    # Noctalia-Plugin-Deps (sonst tote Panels)
    # `bw` für noctalia/bitwarden
    bitwarden-cli
    # für remo/noctes + omp-launcher
    python3
    # für knyrps/nix-search
    nix-search-tv
    # Netzwerk-Diagnose (slipper/network-toolkit 2026-09-25 entfernt)
    nmap
    wireshark
    # `bluetoothctl` (System-Bluetooth)
    bluez
    iw
    # xdg-mime/xdg-open für default-apps u.a.
    xdg-utils
    # Mod+Shift+O war ohne Binary tot
    obsidian
    # orca bewusst NICHT dabei (siehe niri-config)

    # Wayland
    wlsunset

    # MangoWM (PC-Flow, wählbar im Login via F3)
    # Binary `mango` 0.17.3; Session mango.desktop; Config
    # Config ~/.config/mango/config.conf
    mangowc
    # Screenshots in Mango-Binds
    grim
    # Regionsauswahl für grim
    slurp

    (yazi.override {
      _7zz = _7zz-rar; # Support for RAR extraction
    })

    # System-Integration (Niri-Binds brauchen das)
    # `notify-send`-Fallback in deinen Binds
    libnotify
    # Polkit-Agent: Autostart via niri (läuft sonst gar nicht — pgrep leer am 2026-09-24)
    polkit_gnome
  ];

  # Polkit-Auth-Dialoge (sonst stille Abbrüche bei mount Brenn etc.)
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

  # nie anfassen (gilt auch bei Kanal-Updates)
  # Acer Spin SP314-51: intel_vbtn meldet Tablet-Modus -> Keyboard+Touchpad tot
  boot.blacklistedKernelModules = ["intel_vbtn"];

  system.stateVersion = "26.05";
}
