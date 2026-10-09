{
  pkgs,
  inputs,
  lib,
  ...
}: let
  # Application bundles: SINGLE source of truth for the installer TUI and
  # home.packages. Bundle names are stable identifiers the installer writes
  # into hosts/nixos/local.nix (lysec.bundles). Default = all bundles, which
  # Default: alle Bundles = Obermenge des alten Sets (plus jq/nil/alejandra/nh,
  # die parallel auch als systemPackages in modules/nixos/nix.nix stehen;
  # beide Pfade installieren sie, Nix dedupliziert den Store — Absicht, kein Bug).
  #
  # Rules: no package in two bundles; flake-input packages resolve here, not
  # in the TUI; heavy builds stay gated by lysec.buildFromSource in default.nix.
  sys = pkgs.stdenv.hostPlatform.system;
  bundles = {
    core = with pkgs; [
      tmux
      starship
      eza
      fzf
      zoxide
      bat
      fd
      ripgrep
      git
      tree
      unzip
      zip
      file
      wget
      psmisc
      gdu
      jq
      nix-search-tv
      nil
      alejandra
      nh
      bitwarden-cli
      python3
      nodejs
      ffmpeg
      appimage-run
      xdg-utils
    ];
    terminal = with pkgs; [
      foot
      alacritty
      cava
    ];
    editor = with pkgs; [
      zed-editor
      neovim
    ];
    desktop = with pkgs; [
      walker
      nautilus
      file-roller
      adwaita-icon-theme
      yaru-theme
      bibata-cursors
      qt6Packages.qt6ct
      inkscape
      # wl-clipboard + libnotify: via desktops/shared/home.nix (immer an).
      grim
      slurp
      wlsunset
      swaylock
      xwayland-satellite
      polkit_gnome
      fastfetch
      btop
      brightnessctl
      wiremix
      playerctl
      qalculate-qt
      libqalculate
    ];
    browser = [
      inputs.zen-browser.packages.${sys}.default
    ];
    dev = with pkgs; [
      gh
      lazygit
      lazydocker
      pi-coding-agent
      opencode
      inputs.omp.packages.${sys}.omp
    ];
    latex = with pkgs; [
      texlive.combined.scheme-small
      texlab
      zathura
    ];
    notes = with pkgs; [
      obsidian
      readest
    ];
    media = with pkgs; [
      kew
      cliamp
      imv
      chafa
      mpv
      mpd
      mpc
      rmpc
    ];
    gaming = with pkgs; [
      prismlauncher
      steam-run
      osu-lazer-bin
    ];
    chat = with pkgs; [
      flare-signal
      inputs.concord.packages.${sys}.default
      inputs.sonora.packages.${sys}.sonora-bin
    ];
    net = with pkgs; [
      nmap
      bluez
      iw
    ];
    fun = [
      inputs.toofan.packages.${sys}.default
    ];
    shell = [
      inputs.noctalia.packages.${sys}.default
      pkgs.noctalia-greeter
    ];
  };
  # yazi braucht das nicht-freie _7zz-rar-Override — ausserhalb `with pkgs`,
  # damit der Scope explizit bleibt.
  extras = [(pkgs.yazi.override {_7zz = pkgs._7zz-rar;})];
in {
  inherit bundles extras;
  names = builtins.attrNames bundles;
  # Human-readable one-liners for the installer menu (short on purpose:
  # the TUI shows name + blurb, never the full package list).
  blurbs = {
    core = "CLI basis: fish/git/starship, nix tools, utils";
    terminal = "foot/alacritty + cava";
    editor = "Zed (default) + Neovim (LazyVim layer)";
    desktop = "walker, nautilus, wayland helpers, btop/fastfetch";
    browser = "Zen browser (pinned flake input)";
    dev = "gh, lazygit/lazydocker, coding agents (pi, opencode, omp)";
    latex = "texlive-small + texlab + zathura";
    notes = "obsidian, readest";
    media = "mpd+mpc+rmpc, kew, mpv/imv";
    gaming = "prismlauncher, steam-run, osu-lazer";
    chat = "flare-signal, concord, sonora";
    net = "nmap, bluetooth tools";
    fun = "toofan typing test (flake input)";
    shell = "Noctalia shell + greeter (always on)";
  };
  # Resolve a selected bundle list to packages; unknown names abort the
  # build with the valid list (fail fast, never silently skip).
  resolve = selected:
    assert lib.assertMsg (builtins.all (b: bundles ? ${b}) selected)
    "Unknown bundle in lysec.bundles: ${toString (builtins.filter (b: !(bundles ? ${b})) selected)}. Valid: ${toString (builtins.attrNames bundles)}";
      builtins.concatMap (b: bundles.${b}) selected;
}
