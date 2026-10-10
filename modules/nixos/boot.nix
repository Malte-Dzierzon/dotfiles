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
    # Theme: Noctalia-Dark (BG #070e15, Text #e9efeb, Akzent #97a6bb).
    # Wallpaper als Repo-Asset (Flakes sind pure — /home-Pfade verboten).
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
    # NixOS-Generationen gruppiert das Modul selbst als /+Dir ("expandiert").
    # Windows: efi_boot_entry nutzt den bestehenden UEFI-Eintrag "Windows Boot
    # Manager" (Boot0000, ESP PARTUUID 0e6d684e-... auf nvme0n1p1). Kein
    # hdd()-Raten ueber physische Plattennummern; direkter Pfad ungeprueft
    # (ESP ohne root nicht mountbar), daher bewusst NICHT als Primaerweg.
    extraEntries = ''
      /Windows
        protocol: efi_boot_entry
        entry: Windows Boot Manager
    '';
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Acer Spin SP314-51: intel_vbtn meldet Tablet-Modus -> Keyboard+Touchpad tot.
  # Nur Laptop-Profil; Desktops bekommen den Quirk nie (lysec.profile).
  boot.blacklistedKernelModules = lib.optionals (config.lysec.profile == "laptop") ["intel_vbtn"];
  # XP-Pen driver creates virtual pen devices via /dev/uinput.
  boot.kernelModules = ["uinput"];
}
