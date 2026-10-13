{
  pkgs,
  inputs,
  osConfig,
  lib,
  ...
}: let
  # Weak machine: do NOT build heavy packages from Nix (takes forever),
  # use AppImage/binary via install.sh instead. Strong PC: everything from Nix.
  fromSource = osConfig.lysec.buildFromSource;
  b = import ./bundles.nix {inherit pkgs inputs lib;};
  # Noctalia shell+greeter are not a bundle (always on: desktop + login).
  selected = builtins.filter (x: x != "shell") osConfig.lysec.bundles;
in {
  home.packages =
    b.resolve selected
    ++ b.extras
    ++ b.bundles.shell
    # Heavy builds only on a strong machine; weak laptop uses AppImages (install.sh).
    ++ (lib.optionals fromSource [pkgs.lmstudio]);
}
