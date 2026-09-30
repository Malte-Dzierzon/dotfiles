{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Basis / Desktop
    walker zed-editor nautilus file-roller zip tmux starship eza fzf zoxide
    bat fd ripgrep fastfetch brightnessctl noctalia-greeter btop git tree
    unzip file wget psmisc
    # Entwicklung / Git
    gh lazygit lazydocker
    # Medien
    kew imv chafa wiremix playerctl mpv
    # Utilities
    libqalculate gdu bitwarden-cli python3 nix-search-tv
    nmap wireshark bluez iw xdg-utils obsidian
    # Wayland
    wlsunset grim slurp
    polkit_gnome
    (yazi.override { _7zz = _7zz-rar; })
    nodejs zettlr
  ];
}
