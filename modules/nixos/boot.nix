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
