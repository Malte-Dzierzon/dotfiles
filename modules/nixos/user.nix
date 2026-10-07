{
  config,
  pkgs,
  ...
}: {
  networking.hostName = config.lysec.hostname;
  users.users.${config.lysec.username} = {
    isNormalUser = true;
    description = config.lysec.username;
    shell = pkgs.zsh;
    extraGroups = ["networkmanager" "wheel" "docker"];
  };
  users.defaultUserShell = pkgs.zsh;
  security.sudo.extraRules = [
    {
      users = [config.lysec.username];
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
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  services.journald.extraConfig = ''
    SystemMaxUse=200M
    SystemKeepFree=1G
  '';
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;
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
  environment.variables = {
    QT_QPA_PLATFORM = "wayland";
    GTK_IM_MODULE = "";
    QT_IM_MODULE = "";
    EDITOR = "zeditor --wait";
    VISUAL = "zeditor --wait";
  };
  # Live-Stand: nur gtk-Portal extra; kein config.common-Override (Umbriel-Modul setzt Default).
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [xdg-desktop-portal-gtk];
  };
  security.pam.services.swaylock = {};
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
}
