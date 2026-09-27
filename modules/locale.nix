# Timezone, locale, keyboard. Read back by session.nix and umbriel.nix.
{
  flake.nixosModules.locale = { constants, ... }: {
    time.timeZone = constants.timeZone;
    i18n.defaultLocale = constants.locale;
    services.xserver.xkb.layout = constants.layout;
  };
}
