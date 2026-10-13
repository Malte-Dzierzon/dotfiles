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
    omp.url = "github:can1357/oh-my-pi";
    omp.inputs.nixpkgs.follows = "nixpkgs";
    umbriel.url = "github:noctalia-dev/umbriel";
    # NO nixpkgs-follows: umbriel needs wlroots >= 0.20.1 (uses
    # wlr_surface_output.suspended), nixos-26.05 has 0.20.0. So it builds
    # against its own unstable (pinned in flake.lock).
    # Godot 4.7+ etc.: selectively newer packages from unstable,
    # without moving the system nixpkgs pin (26.05).
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    nixpkgs,
    home-manager,
    umbriel,
    nixpkgs-unstable,
    ...
  } @ inputs: let
    host = import ./hosts/nixos/settings.nix;
    inherit (host) system;
    # Effective username: local.nix (installer selection) wins over
    # settings.nix — otherwise HM builds for a different user than the system (B1).
    # Path check instead of tryEval: if the file is missing, settings.nix applies.
    localLysec =
      if builtins.pathExists ./hosts/nixos/local.nix
      then (import ./hosts/nixos/local.nix {lib = nixpkgs.lib;}).lysec or {}
      else {};
    username =
      if localLysec ? username
      then localLysec.username
      else host.username;
  in {
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs host;};
      modules = [
        umbriel.nixosModules.default
        ./modules/lysec.nix
        # mkDefault: hosts/nixos/local.nix (Installer-Auswahl, git-ignoriert)
        # ueberschreibt einzelne lysec-Werte, Rest folgt settings.nix.
        ({lib, ...}: {lysec = lib.mkDefault (host // localLysec);})
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
