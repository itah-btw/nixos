# Timezone, locale, keyboard. xkb here is the single source of truth:
# Umbriel and the greeter read it back (home/umbriel.nix, desktop/session.nix).
{ ... }:
{
  flake.nixosModules.locale = {
    time.timeZone = "Asia/Jakarta";
    i18n.defaultLocale = "en_US.UTF-8";
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };
}
