{
  lib,
  pkgs,
  ...
}: {
  services.displayManager.sessionPackages = [pkgs.niri];
  environment.pathsToLink = ["/share/wayland-sessions"];
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    home = "/var/lib/noctalia-greeter";
    createHome = false;
  };
  users.groups.greeter = {};
  services.greetd = {
    enable = true;
    settings.default_session.user = "greeter";
  };
  systemd.tmpfiles.settings."10-noctalia-greeter" = {
    "/var/lib/noctalia-greeter".d = {
      user = "greeter";
      group = "greeter";
      mode = "0750";
    };
  };
  environment.etc."noctalia-greeter/greeter.toml".text = ''
    [keyboard]
    layout = "de"
    [appearance]
    corner_radius_scale = 0.0
    font_family = "JetBrainsMono NFM"
  '';
  systemd.tmpfiles.rules = [
    "L+ /var/lib/noctalia-greeter/greeter.toml - - - - /etc/noctalia-greeter/greeter.toml"
  ];
  services.greetd.settings.default_session.command = lib.mkDefault "${pkgs.noctalia-greeter}/bin/noctalia-greeter-session";
  services.accounts-daemon.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.noctalia.greeter.sync-appearance" &&
          action.lookup("program") == "${pkgs.noctalia-greeter}/bin/noctalia-greeter-apply-appearance" &&
          action.lookup("user") == "root" &&
          subject.local && subject.active && subject.user == "xealom") {
        return polkit.Result.YES;
      }
    });
  '';
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
}
