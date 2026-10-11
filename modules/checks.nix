# Policy guards, run by `nix build .#checks.x86_64-linux.policy`. One jq predicate
{
  config,
  lib,
  ...
}:
let
  hosts = config.flake.nixosConfigurations;
  constants = config.flake.constants;

  us = builtins.fromJSON "\"\\u001f\"";
  rs = builtins.fromJSON "\"\\u001e\"";

  factsFor =
    name:
    let
      cfg = hosts.${name}.config;
      hm = cfg.home-manager.users.${constants.username} or null;
    in
    {
      inherit name;
      hostName = cfg.networking.hostName or null;
      speechd = cfg.services.speechd.enable or false;
      orca = cfg.services.orca.enable or false;
      firewall = cfg.networking.firewall.enable or false;
      autoGc = cfg.nix.gc.automatic or false;
      xserver = cfg.services.xserver.enable or false;
      oxwm = cfg.services.xserver.windowManager.oxwm.enable or false;
      displayManagers = {
        sddm = cfg.services.displayManager.sddm.enable or false;
        gdm = cfg.services.displayManager.gdm.enable or false;
        lightdm = cfg.services.xserver.displayManager.lightdm.enable or false;
      };
      mysqlBind = cfg.services.mysql.settings.mysqld.bind-address or null;
      mysqlEnabled = cfg.services.mysql.enable or false;
      mysqlWantedBy = cfg.systemd.services.mysql.wantedBy or [ ];
      mediaMountOptions = cfg.fileSystems.${constants.mediaMount}.options or [ ];
      autologinUser = cfg.services.displayManager.sddm.settings.Autologin.User or null;
      sshPasswordAuth = cfg.services.openssh.settings.PasswordAuthentication or null;
      sshKbdAuth = cfg.services.openssh.settings.KbdInteractiveAuthentication or null;
      starshipSettings = if hm != null then (hm.programs.starship.settings or { }) else { };
      starshipPresets = if hm != null then (hm.programs.starship.presets or [ ]) else [ ];
      dconfSettings = if hm != null then (hm.dconf.settings or { }) else { };
      dconfService = cfg.programs.dconf.enable or false;
    };

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
    dual = builtins.sort builtins.lessThan (
      lib.filter (n: builtins.hasAttr n config.flake.homeManagerModules) (
        builtins.attrNames config.flake.nixosModules
      )
    );
    perHost = lib.mapAttrs (_: h: {
      nixos = names h.nixos;
      home = names h.home;
    }) config.flake.hostModules;
    shared = names (
      lib.filter (
        n:
        lib.length (
          lib.filter (h: lib.elem n (h.nixos ++ h.home)) (builtins.attrValues config.flake.hostModules)
        ) > 1
      ) (lib.concatMap (h: h.nixos ++ h.home) (builtins.attrValues config.flake.hostModules))
    );
  };

  expectedConstants = builtins.sort builtins.lessThan [
    "cursorSize"
    "cursorTheme"
    "generationKeep"
    "httpPort"
    "lanIface"
    "layout"
    "locale"
    "localsendPort"
    "mdnsPort"
    "mediaLabel"
    "mediaMount"
    "monoFont"
    "root"
    "sansFont"
    "sshKey"
    "sshPort"
    "timeZone"
    "tvAddress"
    "tvMode"
    "tvOutput"
    "tvRate"
    "username"
    "wlanIface"
  ];

  rules = [
    {
      name = "modules-wired";
      cond = "(.wiring.defined - .wiring.declared) == [] and (.wiring.declared - .wiring.defined) == []";
    }
    {
      name = "dual-namespace-wired";
      cond = ''
        .wiring as $w
        | $w.perHost | to_entries | all(.[];
            . as $e
            | ([ $w.dual[] | select(. as $d | ($e.value.nixos | index($d)) != null) ]) as $a
            | ([ $w.dual[] | select(. as $d | ($e.value.home | index($d)) != null) ]) as $b
            | ($a - $b) == [] and ($b - $a) == [])
      '';
    }
    {
      name = "tv-prefix";
      cond = ''
        .wiring as $w
        | def isTv: startswith("tv-");
          def wired($h): $h.nixos + $h.home;
          def unprefixedUnshared: (isTv | not) and (. as $n | $w.shared | index($n) == null);
          def onTv: [ wired($w.perHost.tv)[] | select(unprefixedUnshared) ] | length;
          def offTv: [ $w.perHost | to_entries[] | select(.key != "tv") | wired(.value)[] | select(isTv) ] | length;
          onTv == 0 and offTv == 0
      '';
    }
    {
      name = "wiring-sorted";
      cond = ".wiring.perHost | to_entries | all(.[]; (.value.nixos == (.value.nixos | sort)) and (.value.home == (.value.home | sort)))";
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
      # tv's DM is pinned to sddm; hp runs no DM at all (getty autologin on
      # tty1 execs startx from the login shell), so any DM there — including
      # nixpkgs' lightdm-by-default — goes red.
      cond = ''
        .hosts | to_entries | all(.[];
          (.key) as $host
          | (.value.displayManagers) as $d
          | ([ $d | to_entries[] | select(.value == true) | .key ]) as $on
          | (if $host == "tv" then "sddm" else null end) as $want
          | if $want == null then ($on | length) == 0
            else (($on | length) == 1 and ($on[0]) == $want) end)
      '';
    }
    {
      name = "no-tts";
      cond = ".hosts | all(.[]; (.speechd == false and .orca == false))";
    }
    {
      name = "no-x-server";
      # hp runs oxwm on Xorg, so Xorg is allowed exactly there; every other
      # host stays X-free.
      cond = ".hosts | all(.[]; if .oxwm then true else .xserver == false end)";
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
      name = "mariadb-loopback";
      cond = ''.hosts | all(.[]; .mysqlBind == null or .mysqlBind == "127.0.0.1")'';
    }
    {
      name = "mariadb-not-autostarted";
      # Installed and configured, but wired into no boot target -- `enable = false`
      # would also satisfy this while making it unstartable on demand.
      cond = ''
        .hosts | all(.[];
          if .mysqlEnabled then (.mysqlWantedBy | length) == 0 else true end)
      '';
    }
    {
      name = "media-mount-timeout";
      # `nofail` alone still lets a slow spin-up cost systemd's 90s default.
      cond = ''
        .hosts | all(.[];
          if (.mediaMountOptions | length) == 0 then true
          else (.mediaMountOptions | map(select(startswith("x-systemd.device-timeout="))) | length) >= 1
          end)
      '';
    }
    {
      name = "tv-appliance-posture";
      # Single-host on purpose: this encodes a decision about the tv box (autologin
      # into a session with no lock screen, reachable over ssh), not a general rule.
      cond = ''
        def ok($h): ($h.autologinUser != null) and ($h.sshPasswordAuth == false) and ($h.sshKbdAuth == false);
        .hosts | if has("tv") then ok(.tv) else true end
      '';
    }
    {
      name = "starship-unmanaged";
      cond = ".hosts | all(.[]; (.starshipSettings == {}) and (.starshipPresets == []))";
    }
    {
      name = "dconf-service-present";
      # HM's dconfSettings activation hard-fails when ca.desrt.dconf is not
      # activatable, aborting the whole activation before any links land.
      cond = ".hosts | all(.[]; if .dconfSettings == {} then true else .dconfService end)";
    }
  ];

  facts = {
    inherit wiring;
    constants = builtins.attrNames constants;
    hosts = lib.listToAttrs (map (n: lib.nameValuePair n (factsFor n)) (builtins.attrNames hosts));
  };

  # A fact that only appears as a prefix of another fact's name (`.host` in
  # `.hosts`) must not count as read.
  unusedFacts = lib.filter (
    k: !lib.any (r: builtins.match ".*\\.${k}($|[^A-Za-z0-9_].*)" r.cond != null) rules
  ) (builtins.attrNames facts);

  blob =
    assert unusedFacts == [ ];
    builtins.toJSON facts;
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
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
                  jq "$cond" "$blobPath" 2>&1 | sed 's/^/       /' | head -50
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
