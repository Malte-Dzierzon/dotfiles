{
  description = "xealom dotfiles - NixOS (niri + Noctalia)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    toofan.url = "github:vyrx-dev/toofan";
    toofan.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      host = import ./hosts/nixos/settings.nix;
      inherit (host) system username desktop;
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs host desktop; };
        modules = [
          ./modules/lysec
          { lysec = host; }
          ./hosts/nixos/configuration.nix
          (
            { lib, ... }:
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                overwriteBackup = true;
                extraSpecialArgs = { inherit inputs desktop; };
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
