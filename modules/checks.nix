# Flake-level validation guards, built by `nix flake check`.
#
# Encodes this machine's tribal rules as derivations so regressions fail
# loudly instead of relying on manual eval asserts:
#   - host identity matches the flake attribute name
#   - exactly one display manager enabled (+ greetd when greeter-based)
#   - no text-to-speech
#   - Noctalia theming stays runtime-managed (no theme/wallpaper/backdrop
#     keys, no declarative custom palettes)
#   - Noctalia composition (Umbriel autostart => no systemd units)
#   - Noctalia binary cache wired, MariaDB loopback-only
#   - starship.toml stays runtime-managed by Noctalia (no HM settings/presets)
#
# One entry per host in `checkedHosts`. Hosts without the Noctalia home
# module automatically skip the Noctalia guards (`or` defaults in
# factsFor); the DM guard counts enabled DMs instead of naming one.
{ config, lib, ... }:
let
  hosts = config.flake.nixosConfigurations;
  checkedHosts = [ "hp" ];

  factsFor =
    pkgs: name:
    let
      cfg = hosts.${name}.config;
      hm = cfg.home-manager.users.itah or null;
      hmNoctalia = if hm != null then (hm.programs.noctalia or null) else null;
    in
    pkgs.writeText "${name}-facts.json" (
      builtins.toJSON {
        wantHost = name;
        hostName = cfg.networking.hostName or null;
        speechd = cfg.services.speechd.enable or false;
        displayManagers = {
          noctalia-greeter = cfg.services.displayManager.noctalia-greeter.enable or false;
          sddm = cfg.services.displayManager.sddm.enable or false;
          gdm = cfg.services.displayManager.gdm.enable or false;
        };
        greetd = cfg.services.greetd.enable or false;
        substituters = cfg.nix.settings.extra-substituters or [ ];
        mysqlBind = cfg.services.mysql.settings.mysqld.bind-address or null;
        noctaliaSettings = if hmNoctalia != null then hmNoctalia.settings else { };
        customPalettes = if hmNoctalia != null then (hmNoctalia.customPalettes or { }) else { };
        hasNoctalia = hmNoctalia != null && (hmNoctalia.enable or false);
        noctaliaSystemdSystem = cfg.programs.noctalia.systemd.enable or false;
        noctaliaSystemdHome = if hm != null then (hm.programs.noctalia.systemd.enable or false) else false;
        starshipSettings = if hm != null then (hm.programs.starship.settings or { }) else { };
        starshipPresets = if hm != null then (hm.programs.starship.presets or [ ]) else [ ];
        umbrielAutostart =
          if hm != null then (hm.programs.umbriel.settings.general.autostart or null) else null;
      }
    );

  checkFor =
    pkgs: name:
    let
      facts = factsFor pkgs name;
      mkCheck =
        checkName: cond:
        pkgs.runCommand "${name}-${checkName}"
          {
            nativeBuildInputs = [ pkgs.jq ];
          }
          ''
            jq -e '${cond}' "${facts}" > /dev/null \
              || { echo '${name}: CHECK FAILED: ${checkName}' >&2; exit 1; }
            touch "$out"
          '';
    in
    {
      "${name}-host-identity" = mkCheck "host-identity" ".hostName == .wantHost";
      "${name}-no-tts" = mkCheck "no-tts" ".speechd == false";
      "${name}-single-dm" = mkCheck "single-dm" "[.displayManagers[]] | map(select(.)) | length == 1";
      "${name}-greeter-greetd" =
        mkCheck "greeter-greetd" ''if .displayManagers."noctalia-greeter" then .greetd else true end'';
      "${name}-noctalia-theming" = mkCheck "noctalia-theming" ''
        if .hasNoctalia
        then (((.noctaliaSettings | has("theme") or has("wallpaper") or has("backdrop")) | not)
          and (.customPalettes == {}))
        else true end'';
      "${name}-noctalia-composition" = mkCheck "noctalia-composition" ''
        ((.umbrielAutostart // []) | index("noctalia")) as $auto
        | if $auto
          then (.noctaliaSystemdSystem == false and .noctaliaSystemdHome == false)
          else true end'';
      "${name}-binary-cache" =
        mkCheck "binary-cache" ''.substituters | index("https://noctalia.cachix.org") != null'';
      "${name}-mariadb-loopback" =
        mkCheck "mariadb-loopback" ''.mysqlBind == null or .mysqlBind == "127.0.0.1"'';
      # starship.toml is runtime-managed by Noctalia's Starship template
      # (palette sync); HM-managed settings/presets would clobber it on
      # switch and break Noctalia's apply.sh (read-only store symlink).
      "${name}-starship-unmanaged" =
        mkCheck "starship-unmanaged" "(.starshipSettings == {}) and (.starshipPresets == [])";
    };
in
{
  perSystem = { pkgs, ... }: {
    checks = lib.foldl' (acc: name: acc // checkFor pkgs name) { } checkedHosts;
  };
}
