{ pkgs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  programs.nix-ld.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nixpkgs.overlays = [ (import ../../overlays/zen-browser.nix) ];
  environment.systemPackages = with pkgs; [ nh alejandra nil jq ];
}
