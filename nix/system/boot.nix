{
  pkgs,
  config,
  lib,
  ...
}: {
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 10;
  boot.loader.limine = {
    enable = true;
    efiSupport = true;
    biosSupport = false;
    maxGenerations = 15;
    enableEditor = false;
    # Theme: Noctalia dark (bg #070e15, text #e9efeb, accent #97a6bb).
    # Wallpaper as a repo asset (flakes are pure — /home paths forbidden).
    style = {
      wallpapers = [ ../../assets/boot-wallpaper.jpg ];
      wallpaperStyle = "stretched";
      backdrop = "070E15";
      interface = {
        branding = "NixOS";
        brandingColor = "97A6BB";
        helpColor = "9AA7A1";
        helpColorBright = "BBCce7";
      };
      graphicalTerminal = {
        foreground = "E9EFEB";
        brightForeground = "F3F7F3";
        background = "E6070E15";
        brightBackground = "E6131A20";
        palette = "050B10:857960:82967F:96937B:97A6BB:6C7B91:83A2A3:EFF3EF";
        brightPalette = "62676C:BFAE87:A4B89B:BBB999:BBCCE7:8E9FBB:A5C9CA:F3F7F3";
      };
    };
    # The module itself groups NixOS generations as a /+ dir ("expanded").
    # Windows: efi_boot_entry uses the existing UEFI entry "Windows Boot
    # Manager" (Boot0000, ESP PARTUUID 0e6d684e-... on nvme0n1p1). No
    # hdd() guessing over physical disk numbers; direct path unverified
    # (ESP not mountable without root), hence deliberately NOT the primary path.
    extraEntries = ''
      /Windows
        protocol: efi_boot_entry
        entry: Windows Boot Manager
    '';
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Acer Spin SP314-51: intel_vbtn reports tablet mode -> keyboard+touchpad dead.
  # Laptop profile only; desktops never get the quirk (lysec.profile).
  boot.blacklistedKernelModules = lib.optionals (config.lysec.profile == "laptop") ["intel_vbtn"];
  # XP-Pen driver creates virtual pen devices via /dev/uinput.
  boot.kernelModules = ["uinput"];
}
