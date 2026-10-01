{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Terminals (alle Noctalia-thematisiert, Config in configs/dotconfig)
    foot kitty alacritty ghostty
    # Basis / Desktop
    walker zed-editor nautilus file-roller zip tmux starship eza fzf zoxide
    bat fd ripgrep fastfetch brightnessctl noctalia-greeter btop cava git tree
    unzip file wget psmisc rofi
    # Entwicklung / Git
    gh lazygit lazydocker neovim
    # Medien (mpd + mpc + rmpc gehoeren zusammen)
    kew imv chafa wiremix playerctl mpv mpd mpc rmpc
    # Utilities
    libqalculate gdu bitwarden-cli python3 nix-search-tv ffmpeg appimage-run
    nmap wireshark bluez iw xdg-utils obsidian
    # Wayland
    wlsunset grim slurp xwayland-satellite
    polkit_gnome
    (yazi.override { _7zz = _7zz-rar; })
    nodejs zettlr
  ];
}
