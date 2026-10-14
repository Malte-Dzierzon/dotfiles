{pkgs, ...}: {
  # Logitech PRO X Wireless (046d:0aba): standard USB HID consumer-control
  # volume keys (already handled by the compositor) + battery/sidetone
  # via HeadsetControl. udev rules grant user access to /dev/hidraw*.
  environment.systemPackages = [pkgs.headsetcontrol];
  services.udev.packages = [pkgs.headsetcontrol];
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
