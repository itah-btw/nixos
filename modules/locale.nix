# Timezone and locale. Keyboard layout is flake.constants, read by umbriel.nix and
# session.nix; services.xserver.xkb was a value nothing read, no host runs an X server.
{
  flake.nixosModules.locale = { constants, ... }: {
    time.timeZone = constants.timeZone;
    i18n.defaultLocale = constants.locale;
  };
}
