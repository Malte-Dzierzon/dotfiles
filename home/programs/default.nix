{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
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
    grim
    slurp
    xwayland-satellite
    polkit_gnome
    (yazi.override {_7zz = _7zz-rar;})
    nodejs
    zettlr
    pi-coding-agent
    # Gaming / Launcher
    prismlauncher
    steam-run
    # Chat / Calls (user scope, kein Systemdienst)
    concord
    flare-signal
    # Spiele-Binary (AppImage, ausserhalb nixpkgs)
    osu-lazer-bin
  ];
}
