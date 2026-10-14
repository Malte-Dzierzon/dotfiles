{
  pkgs,
  inputs,
  lib,
  ...
}: let
  # Application catalog: SINGLE source of truth for installer TUI, apps.sh,
  # app-list and home.packages.
  #   groups.core — mandatory base, always installed (CLI, terminals,
  #            editors, desktop essentials, Zen, notes, media, net tools).
  #   apps.<id> — individually toggleable optional applications, each with
  #            exactly one package (pkgs or flake input) plus a UI blurb.
  # No separate laptop/desktop groups: CLI/TUI/network tools are identical
  # on both machines (incl. tailscale via the system service in
  # nix/system/remote.nix).
  # Noctalia shell+greeter and yazi are unconditional (outside the catalog).
  # lysec.bundles stores app IDs (e.g. ["godot" "alacritty"]); "core" is
  # implicit and never stored. Legacy group names (14 old bundles, laptop,
  # pc, desktop) expand to app IDs via aliases so existing local.nix
  # selections keep building with the same effective set.
  #
  # Rules: no package in two places; flake-input packages resolve here, not
  # in the TUI; heavy builds stay gated by lysec.buildFromSource in default.nix.
  sys = pkgs.stdenv.hostPlatform.system;
  groups = {
    core = with pkgs; [
      # CLI basis
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
      # terminals (foot default; kitty in core; alacritty is a PC extra)
      foot
      kitty
      cava
      # editors
      zed-editor
      neovim
      gcc # tree-sitter parsers compile on demand
      # desktop essentials
      walker
      nautilus
      file-roller
      adwaita-icon-theme
      yaru-theme
      bibata-cursors
      qt6Packages.qt6ct
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
      # browser + comms + notes (daily drivers)
      inputs.zen-browser.packages.${sys}.default
      flare-signal
      inputs.concord.packages.${sys}.default
      obsidian
      readest
      # dev essentials (cli, not agents)
      gh
      lazygit
      lazydocker
      # small tools
      texlive.combined.scheme-small
      texlab
      zathura
      kew
      cliamp
      imv
      chafa
      mpv
      mpd
      mpc
      rmpc
      krita
      # CLI/TUI/network tools shared by laptop + PC
      bluez
      iw
      linux-wifi-hotspot
      nmap
      inputs.toofan.packages.${sys}.default
    ];
  };
  # Individually toggleable optional applications. One entry per app:
  # package (pkgs or flake input) + short UI blurb. IDs are stable —
  # lysec.bundles stores these IDs.
  apps = {
    alacritty = { pkg = pkgs.alacritty; blurb = "GPU terminal (extra)"; };
    inkscape = { pkg = pkgs.inkscape; blurb = "vector graphics editor"; };
    prismlauncher = { pkg = pkgs.prismlauncher; blurb = "Minecraft launcher"; };
    steam-run = { pkg = pkgs.steam-run; blurb = "run foreign binaries/games"; };
    osu-lazer-bin = { pkg = pkgs.osu-lazer-bin; blurb = "rhythm game"; };
    godot = { pkg = inputs.nixpkgs-unstable.legacyPackages.${sys}.godot; blurb = "game engine"; };
    sonora = { pkg = inputs.sonora.packages.${sys}.sonora-bin; blurb = "audio tool"; };
    omp = { pkg = inputs.omp.packages.${sys}.omp; blurb = "coding agent"; };
    pi-coding-agent = { pkg = pkgs.pi-coding-agent; blurb = "coding agent"; };
    opencode = { pkg = pkgs.opencode; blurb = "coding agent"; };
    temurin-bin = { pkg = pkgs.temurin-bin; blurb = "Java runtime (Filius)"; };
    ffmpeg = { pkg = pkgs.ffmpeg; blurb = "media converter"; };
    appimage-run = { pkg = pkgs.appimage-run; blurb = "run AppImages"; };
    xdg-utils = { pkg = pkgs.xdg-utils; blurb = "desktop integration tools"; };
  };
  # All optional app IDs, order-stable for UIs.
  appIds = ["alacritty" "inkscape" "prismlauncher" "steam-run" "osu-lazer-bin" "godot" "sonora" "omp" "pi-coding-agent" "opencode" "temurin-bin" "ffmpeg" "appimage-run" "xdg-utils"];
  # Back-compat: legacy group/bundle names -> app IDs. Old full selections
  # (all 14 legacy names, core+laptop+pc, core+desktop) expand to all app IDs.
  allAppIds = appIds;
  aliases = {
    core = [];
    terminal = [];
    editor = [];
    browser = [];
    dev = ["godot" "omp" "pi-coding-agent" "opencode" "temurin-bin"];
    latex = [];
    notes = [];
    media = ["ffmpeg"];
    chat = ["omp"];
    net = [];
    fun = [];
    gaming = ["prismlauncher" "steam-run" "osu-lazer-bin"];
    godot = ["godot"];
    shell = [];
    laptop = [];
    pc = allAppIds;
    desktop = allAppIds;
  };
  # so the scope stays explicit.
  extras = [(pkgs.yazi.override {_7zz = pkgs._7zz-rar;})];
  shellPkgs = [
    inputs.noctalia.packages.${sys}.default
    pkgs.noctalia-greeter
  ];
  # bundles: per-ID package view (single truth: core group + apps catalog).
  # Legacy group names resolve through aliases for migration.
  bundles = { core = groups.core; shell = shellPkgs; }
    // builtins.listToAttrs (map (id: { name = id; value = [(apps.${id}.pkg or null)]; }) appIds)
    // builtins.mapAttrs (n: ids: map (id: apps.${id}.pkg) (builtins.filter (id: apps ? ${id}) ids)) (builtins.removeAttrs aliases ["core" "shell" "pc" "desktop"])
    // { pc = map (id: apps.${id}.pkg) allAppIds; desktop = map (id: apps.${id}.pkg) allAppIds; };
in {
  inherit extras groups apps appIds aliases shellPkgs bundles;
  # Selectable app IDs for new UIs (installer, apps.sh, app-list).
  # Core is mandatory (always installed, never offered as a choice).
  names = appIds;
  # All names incl. legacy (for migration display).
  allNames = appIds ++ ["core" "shell" "pc" "desktop"];
  # Human-readable one-liners for the installer menu.
  blurbs = builtins.mapAttrs (id: a: a.blurb) apps // {
    core = "always on: CLI, foot/kitty, editors, desktop, Zen, notes, media, net tools";
    shell = "Noctalia shell + greeter (always on)";
  };
  # Expand any selection (app IDs and/or legacy group names) to app IDs.
  expandGroups = selected:
    let
      mapped = builtins.concatMap (b: if apps ? ${b} then [b] else (aliases.${b} or [b])) selected;
    in lib.unique mapped;
  # Resolve a selection to packages; unknown names abort the build
  # with the valid list (fail fast, never silently skip).
  resolve = selected:
    assert lib.assertMsg (builtins.all (b: (apps ? ${b}) || (aliases ? ${b}) || b == "core" || b == "shell") selected)
    "Unknown app in lysec.bundles. Valid app IDs: ${toString appIds}";
    let
      ids = lib.unique (builtins.concatMap (b: if b == "core" || b == "shell" then [] else if apps ? ${b} then [b] else (aliases.${b} or [])) selected);
      pkgsOf = id: if apps ? ${id} then [apps.${id}.pkg] else [];
    in groups.core ++ builtins.concatMap pkgsOf ids;
}
