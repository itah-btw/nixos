# Flake-level validation guards, built by `nix flake check`. Per host: identity,
# single DM + greetd, no TTS, no X server, firewall + auto-GC on, Noctalia
# theming/composition, binary cache (with key), MariaDB loopback, starship
# unmanaged. Plus one flake-wide guard that every module is wired into a host.
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
      xserver = cfg.services.xserver.enable or false;
      displayManagers = {
        noctalia-greeter = cfg.services.displayManager.noctalia-greeter.enable or false;
        sddm = cfg.services.displayManager.sddm.enable or false;
        gdm = cfg.services.displayManager.gdm.enable or false;
      };
      greetd = cfg.services.greetd.enable or false;
      substituters = cfg.nix.settings.extra-substituters or [ ];
      trustedKeys = cfg.nix.settings.extra-trusted-public-keys or [ ];
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

  # Runs a jq predicate over a JSON blob and fails the build with a message.
  mkAssert =
    pkgs: name: factsFile: cond:
    pkgs.runCommand name { nativeBuildInputs = [ pkgs.jq ]; } ''
      jq -e '${cond}' "${factsFile}" > /dev/null \
        || { echo '${name}: CHECK FAILED' >&2; exit 1; }
      touch "$out"
    '';

  checkFor =
    pkgs: name:
    let
      facts = pkgs.writeText "${name}-facts.json" (builtins.toJSON (factsFor name));
      mkCheck = checkName: cond: mkAssert pkgs "${name}-${checkName}" facts cond;
    in
    {
      "${name}-host-identity" = mkCheck "host-identity" ''.hostName == "${name}"'';
      "${name}-no-tts" = mkCheck "no-tts" ".speechd == false";
      "${name}-firewall" = mkCheck "firewall" ".firewall == true";
      "${name}-auto-gc" = mkCheck "auto-gc" ".autoGc == true";
      # Both sessions are Wayland-only; tv additionally asserts this at build
      # time via nix-store -q on its own closure.
      "${name}-no-x-server" = mkCheck "no-x-server" ".xserver == false";
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
      # Substituter alone is not enough: without the key, Nix refuses the cache.
      "${name}-binary-cache" = mkCheck "binary-cache" ''
        (.substituters | index("https://noctalia.cachix.org")) != null
        and ((.trustedKeys | map(startswith("noctalia.cachix.org-1:")) | any)) == true'';
      "${name}-mariadb-loopback" =
        mkCheck "mariadb-loopback" ''.mysqlBind == null or .mysqlBind == "127.0.0.1"'';
      "${name}-starship-unmanaged" =
        mkCheck "starship-unmanaged" "(.starshipSettings == {}) and (.starshipPresets == [])";
    };

  # Every module this flake defines must be composed by name into at least one
  # host, and every name a host asks for must exist. Catches the failure mode
  # dendritic imports cannot: a file that evaluates fine and is never used.
  wiring =
    let
      hostDir = ./hosts;
      hostFiles = lib.filter (n: lib.hasSuffix ".nix" n) (builtins.attrNames (builtins.readDir hostDir));
      # Whole-line comments are dropped first, so commenting a module out
      # really orphans it. A reference trailing code on the same line would
      # still count; the host files do not use that form.
      hostText = lib.concatStringsSep "\n" (
        lib.filter (line: !(lib.hasPrefix "#" (lib.trim line))) (
          lib.concatMap (n: lib.splitString "\n" (builtins.readFile (hostDir + "/${n}"))) hostFiles
        )
      );
      # After splitting on `config.flake.`, every chunk starts with
      # `nixosModules.<name>` or `homeManagerModules.<name>` followed by the
      # rest of the line, so drop the namespace and read the name.
      nameOf =
        chunk:
        let
          rest =
            if lib.hasPrefix "nixosModules." chunk then
              lib.removePrefix "nixosModules." chunk
            else if lib.hasPrefix "homeManagerModules." chunk then
              lib.removePrefix "homeManagerModules." chunk
            else
              null;
          matched = if rest == null then null else builtins.match "([A-Za-z0-9_-]+).*" rest;
        in
        if matched == null then null else lib.head matched;
      referenced = builtins.filter (n: n != null) (
        map nameOf (lib.tail (lib.splitString "config.flake." hostText))
      );
      defined =
        builtins.attrNames config.flake.nixosModules ++ builtins.attrNames config.flake.homeManagerModules;
    in
    {
      defined = builtins.sort builtins.lessThan defined;
      referenced = lib.foldl' (acc: n: if lib.elem n acc then acc else acc ++ [ n ]) [ ] referenced;
    };
in
{
  perSystem = { pkgs, ... }: {
    checks = (lib.foldl' (acc: name: acc // checkFor pkgs name) { } checkedHosts) // {
      modules-wired = mkAssert pkgs "modules-wired" (pkgs.writeText "wiring.json" (
        builtins.toJSON wiring
      )) "(.defined - .referenced) == [] and (.referenced - .defined) == []";
    };
  };
}
