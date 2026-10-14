{pkgs, ...}: {
  home.packages = with pkgs; [wl-clipboard libnotify];
  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };
}
