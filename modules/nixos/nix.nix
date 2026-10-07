{pkgs, ...}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];
  programs.nix-ld.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix.settings.auto-optimise-store = true;
  # NICHT kuerzer: sonst fliegt der Gen-54-Rollback (Mesa 26.1.8) weg
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  environment.systemPackages = with pkgs; [nh alejandra nil jq];
}
