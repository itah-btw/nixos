# Policy guards, run by `nix flake check`. Every rule is a jq predicate over one
# JSON blob describing the whole flake, so they are a single derivation and one
# build reports every failure at once. Rules are `all(.[]; ...)` over the
# per-host facts rather than repeated per host: a rule for a feature only one
# host has is vacuous on the other.
{
  config,
  lib,
  ...
}:
let
  hosts = config.flake.nixosConfigurations;
  constants = config.flake.constants;

  # US separates a rule's name from its condition, RS separates records. Neither
  # can occur in a rule, and this keeps multi-line jq programs intact.
  us = builtins.fromJSON "\"\\u001f\"";
  rs = builtins.fromJSON "\"\\u001e\"";

  factsFor =
    name:
    let
      cfg = hosts.${name}.config;
      hm = cfg.home-manager.users.${constants.username} or null;
      hmNoctalia = if hm != null then (hm.programs.noctalia or null) else null;
    in
    {
      inherit name;
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

  # Sorted and de-duplicated: order-insensitive, and a name in both namespaces
  # (mariadb, shell) collapses to one.
  names =
    xs:
    builtins.sort builtins.lessThan (
      lib.foldl' (acc: n: if lib.elem n acc then acc else acc ++ [ n ]) [ ] xs
    );

  wiring = {
    defined = names (
      builtins.attrNames config.flake.nixosModules ++ builtins.attrNames config.flake.homeManagerModules
    );
    declared = names (
      lib.concatMap (h: h.nixos ++ h.home) (builtins.attrValues config.flake.hostModules)
    );
    # A name in both namespaces (mariadb, shell) collapses to one entry above,
    # so the union comparison cannot see a host that wired only one side of it.
    # dual-namespace-wired closes that.
    dual = builtins.sort builtins.lessThan (
      lib.filter (n: builtins.hasAttr n config.flake.homeManagerModules) (
        builtins.attrNames config.flake.nixosModules
      )
    );
    perHost = lib.mapAttrs (_: h: {
      nixos = names h.nixos;
      home = names h.home;
    }) config.flake.hostModules;
  };

  # Guards against a typo, which would otherwise evaluate to "" and silently
  # blank out a username, a path or a layout.
  expectedConstants = builtins.sort builtins.lessThan [
    "locale"
    "layout"
    "root"
    "timeZone"
    "tvAddress"
    "username"
  ];

  rules = [
    {
      name = "modules-wired";
      # Both directions: an unreferenced module is dead, and an unknown name
      # would fail later and less clearly.
      cond = "(.wiring.defined - .wiring.declared) == [] and (.wiring.declared - .wiring.defined) == []";
    }
    {
      name = "dual-namespace-wired";
      # A host that wires a module in both namespaces has to wire both sides:
      # the nixosModules half alone would satisfy modules-wired.
      cond = ''
        .wiring as $w
        | $w.perHost | to_entries | all(.[];
            . as $e
            | ([ $w.dual[] | select(. as $d | ($e.value.nixos | index($d)) != null) ]) as $a
            | ([ $w.dual[] | select(. as $d | ($e.value.home | index($d)) != null) ]) as $b
            | $a == $b)
      '';
    }
    {
      name = "constants-intact";
      cond = "(.constants | sort) == ${builtins.toJSON expectedConstants}";
    }
    {
      name = "host-identity";
      cond = ".hosts | to_entries | all(.[]; .value.hostName == .key)";
    }
    {
      name = "single-dm";
      cond = ".hosts | all(.[]; [.displayManagers[]] | map(select(.)) | length == 1)";
    }
    {
      name = "greeter-implies-greetd";
      cond = ''.hosts | all(.[]; if .displayManagers."noctalia-greeter" then .greetd else true end)'';
    }
    {
      name = "no-tts";
      cond = ".hosts | all(.[]; .speechd == false)";
    }
    {
      name = "no-x-server";
      cond = ".hosts | all(.[]; .xserver == false)";
    }
    {
      name = "firewall";
      cond = ".hosts | all(.[]; .firewall == true)";
    }
    {
      name = "auto-gc";
      cond = ".hosts | all(.[]; .autoGc == true)";
    }
    {
      name = "binary-cache";
      # Without the key Nix refuses the substituter.
      cond = ''
        .hosts | all(.[];
          (.substituters | index("https://noctalia.cachix.org")) != null
          and ((.trustedKeys | map(startswith("noctalia.cachix.org-1:")) | any)) == true)
      '';
    }
    {
      name = "mariadb-loopback";
      cond = ''.hosts | all(.[]; .mysqlBind == null or .mysqlBind == "127.0.0.1")'';
    }
    {
      name = "noctalia-theming-runtime";
      # Theming stays Noctalia's.
      cond = ''
        .hosts | all(.[];
          if .hasNoctalia
          then (((.noctaliaSettings | has("theme") or has("wallpaper") or has("backdrop")) | not)
            and (.customPalettes == {}))
          else true end)
      '';
    }
    {
      name = "noctalia-single-launcher";
      # Umbriel starts Noctalia, systemd must not.
      cond = ''
        .hosts | all(.[];
          ((.umbrielAutostart // []) | index("noctalia")) as $auto
          | if $auto
            then (.noctaliaSystemdSystem == false and .noctaliaSystemdHome == false)
            else true end)
      '';
    }
    {
      name = "starship-unmanaged";
      # starship.toml is Noctalia's; HM would make it a read-only symlink.
      cond = ".hosts | all(.[]; (.starshipSettings == {}) and (.starshipPresets == []))";
    }
  ];

  blob = builtins.toJSON {
    inherit wiring;
    constants = builtins.attrNames constants;
    hosts = lib.listToAttrs (map (n: lib.nameValuePair n (factsFor n)) (builtins.attrNames hosts));
  };
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        # Per-rule verdict, and all failures reported together.
        policy =
          pkgs.runCommand "flake-policy"
            {
              nativeBuildInputs = [ pkgs.jq ];
              passAsFile = [
                "blob"
                "rules"
              ];
              inherit blob;
              USCHAR = us;
              rules = builtins.concatStringsSep rs (map (r: "${r.name}${us}${r.cond}") rules) + rs;
            }
            ''
              status=0
              while IFS= read -r -d "$(printf '\036')" record; do
                [ -n "$record" ] || continue
                name=''${record%%"$USCHAR"*}
                cond=''${record#*"$USCHAR"}
                if jq -e "$cond" "$blobPath" > /dev/null 2>&1; then
                  echo "ok   $name"
                else
                  echo "FAIL $name"
                  jq "$cond" "$blobPath" 2>&1 | sed 's/^/       /' | head -10
                  status=1
                fi
              done < "$rulesPath"
              if [ "$status" -ne 0 ]; then
                echo >&2
                echo "flake-policy: FAILED" >&2
                exit 1
              fi
              touch "$out"
            '';
      };
    };
}
