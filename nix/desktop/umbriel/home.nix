{...}: {
  imports = [../shared/home.nix];
  # Umbriel config is a writable repo symlink (apply.sh), not HM-managed.
  home.packages = [];
}
