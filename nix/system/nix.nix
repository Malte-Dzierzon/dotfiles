{pkgs, ...}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];
  programs.nix-ld.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix.settings.auto-optimise-store = true;
  # Rollback window: only 7 days — older generations ate ~40 GB of store.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  environment.systemPackages = with pkgs; [nh alejandra nil jq];
}
