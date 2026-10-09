{config, ...}: let
  cfg = config.lysec;
in {
  time.timeZone = cfg.timezone;
  i18n.defaultLocale = cfg.mainLocale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = cfg.regionalLocale;
    LC_IDENTIFICATION = cfg.regionalLocale;
    LC_MEASUREMENT = cfg.regionalLocale;
    LC_MONETARY = cfg.regionalLocale;
    LC_NAME = cfg.regionalLocale;
    LC_NUMERIC = cfg.regionalLocale;
    LC_PAPER = cfg.regionalLocale;
    LC_TELEPHONE = cfg.regionalLocale;
    LC_TIME = cfg.regionalLocale;
  };
  services.xserver.xkb = {
    layout = cfg.keyboardLayout;
    variant = "";
  };
  console.keyMap = cfg.consoleKeyMap;
}
