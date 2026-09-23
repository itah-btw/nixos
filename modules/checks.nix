# Flake-level validation guards, built by `nix flake check`: host identity,
# single DM + greetd, no TTS, Noctalia theming/composition/cache, MariaDB
# loopback, starship unmanaged, firewall + auto-GC on.
{ config, lib, ... }:
let
  hosts = config.flake.nixosConfigurations;
  checkedHosts = builtins.attrNames hosts;

  factsFor =
    name:
    let
      cfg = hosts.${name}.config;
      hm = cfg.home-manager.users.itah or null;
      hmNoctalia = if hm != null then (hm.programs.noctalia or null) else null;
    in
    {
      hostName = cfg.networking.hostName or null;
      speechd = cfg.services.speechd.enable or false;
      firewall = cfg.networking.firewall.enable or false;
      autoGc = cfg.nix.gc.automatic or false;
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
    };

  checkFor =
    pkgs: name:
    let
      facts = pkgs.writeText "${name}-facts.json" (builtins.toJSON (factsFor name));
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
      "${name}-host-identity" = mkCheck "host-identity" ''.hostName == "${name}"'';
      "${name}-no-tts" = mkCheck "no-tts" ".speechd == false";
      "${name}-firewall" = mkCheck "firewall" ".firewall == true";
      "${name}-auto-gc" = mkCheck "auto-gc" ".autoGc == true";
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
      "${name}-starship-unmanaged" =
        mkCheck "starship-unmanaged" "(.starshipSettings == {}) and (.starshipPresets == [])";
    };
in
{
  perSystem = { pkgs, ... }: {
    checks = lib.foldl' (acc: name: acc // checkFor pkgs name) { } checkedHosts;
  };
}
