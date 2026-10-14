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
  # Core is mandatory (always installed, independent of selection).
  # lysec.bundles stores optional app IDs; legacy group names expand
  # via aliases. "shell"/"core" entries are accepted and ignored
  # (core is implicit, shell resolves separately and is never doubled).
  raw = builtins.filter (x: x != "shell" && x != "core") osConfig.lysec.bundles;
  ids = b.expandGroups raw;
in {
  home.packages =
    b.resolve ids
    ++ b.extras
    ++ b.shellPkgs
    # Heavy builds only on a strong machine; weak laptop uses AppImages (install.sh).
    ++ (lib.optionals fromSource [pkgs.lmstudio]);
}
