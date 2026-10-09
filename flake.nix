{
  description = "Malte-Dzierzon dotfiles - NixOS (umbriel + Noctalia)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    toofan.url = "github:vyrx-dev/toofan";
    toofan.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    noctalia.url = "github:noctalia-dev/noctalia";
    noctalia.inputs.nixpkgs.follows = "nixpkgs";
    concord.url = "github:chojs23/concord";
    concord.inputs.nixpkgs.follows = "nixpkgs";
    sonora.url = "github:sonorahq/sonora";
    sonora.inputs.nixpkgs.follows = "nixpkgs";
    umbriel.url = "github:noctalia-dev/umbriel";
    umbriel.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    home-manager,
    umbriel,
    ...
  } @ inputs: let
    host = import ./hosts/nixos/settings.nix;
    inherit (host) system username;
  in {
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs host;};
      modules = [
        umbriel.nixosModules.default
        ./modules/lysec
        {lysec = host;}
        ./hosts/nixos/default.nix
        (
          {lib, ...}: {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              overwriteBackup = true;
              extraSpecialArgs = {inherit inputs;};
              users.${username} = import ./home-entry.nix;
            };
            systemd.services."home-manager-${username}".serviceConfig.TimeoutStartSec = lib.mkForce "30m";
          }
        )
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
