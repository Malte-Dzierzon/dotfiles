{
  pkgs,
  inputs,
  osConfig,
  lib,
  ...
}: let
  # Schwache Maschine: schwere Pakete NICHT aus Nix bauen (dauert ewig),
  # stattdessen AppImage/Binary per install.sh. Starker PC: alles aus Nix.
  fromSource = osConfig.lysec.buildFromSource;
  b = import ./bundles.nix {inherit pkgs inputs lib;};
  # Noctalia shell+greeter sind kein Bundle (immer an: Desktop + Login).
  selected = builtins.filter (x: x != "shell") osConfig.lysec.bundles;
in {
  home.packages =
    b.resolve selected
    ++ b.extras
    ++ b.bundles.shell
    # Schwere Builds nur auf starker Maschine; schwacher Laptop nutzt AppImages (install.sh).
    ++ (lib.optionals fromSource [pkgs.lmstudio]);
}
