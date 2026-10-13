{...}: {
  imports = [../shared/home.nix];
  # umbriel config comes from configs/umbriel (home.file link in home-entry.nix)
  home.packages = [];
}
