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
      pipewire = cfg.services.pipewire.enable or false;
      displayManagers = {
        sddm = cfg.services.displayManager.sddm.enable or false;
        gdm = cfg.services.displayManager.gdm.enable or false;
        lightdm = cfg.services.xserver.displayManager.lightdm.enable or false;
      };
      mysqlBind = cfg.services.mysql.settings.mysqld.bind-address or null;
      mysqlEnabled = cfg.services.mysql.enable or false;
      mysqlWantedBy = cfg.systemd.services.mysql.wantedBy or [ ];
      httpdEnabled = cfg.services.httpd.enable or false;
      httpdListen = cfg.services.httpd.virtualHosts.localhost.listenAddresses or null;
      starshipSettings = if hm != null then (hm.programs.starship.settings or { }) else { };
      starshipPresets = if hm != null then (hm.programs.starship.presets or [ ]) else [ ];
      dconfSettings = if hm != null then (hm.dconf.settings or { }) else { };
      dconfService = cfg.programs.dconf.enable or false;
    };

  names = xs: lib.sort lib.lessThan (lib.unique xs);

  wiring = {
    rawLists = lib.concatMap (h: [
      h.nixos
      h.home
    ]) (builtins.attrValues config.flake.hostModules);
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
  };

  expectedConstants = builtins.sort builtins.lessThan [
    "cursorSize"
    "cursorTheme"
    "generationKeep"
    "layout"
    "locale"
    "localsendPort"
    "mdnsPort"
    "monoFont"
    "root"
    "sansFont"
    "timeZone"
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
      name = "oxwm-themes-wired";
      # oxwm's bare-name spawns (st, dmenu_run, dunst) only resolve through
      # the dispatcher wrappers oxwm-themes installs; without it the session
      # comes up with no terminal and no menus.
      cond = ''
        .wiring.perHost | to_entries | all(.[];
          (.value.home | index("oxwm")) == null or (.value.home | index("oxwm-themes")) != null)
      '';
    }
    {
      name = "wiring-sorted";
      cond = ".wiring.perHost | to_entries | all(.[]; (.value.nixos == (.value.nixos | sort)) and (.value.home == (.value.home | sort)))";
    }
    {
      name = "wiring-distinct";
      # `names` dedups silently, so modules-wired cannot see a doubled entry
      # in one list (oxwm is legitimately in both lists at once); a duplicate
      # still reorders list options and moves the store hash.
      cond = ".wiring.rawLists | all(.[]; length == (unique | length))";
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
      # hp runs no DM at all (getty autologin on tty1 execs startx from the
      # login shell), so any DM — including nixpkgs' lightdm-by-default — goes red.
      cond = ''
        .hosts | all(.[]; ([.displayManagers | to_entries[] | select(.value == true)]) | length == 0)
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
      name = "audio-present";
      # Nothing declares the audio stack: it rides in on graphical-desktop.nix
      # (xserver on) via mkDefault, so assert it rather than discovering its
      # absence through silent keybinds.
      cond = ".hosts | all(.[]; .pipewire == true)";
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
      name = "httpd-loopback";
      # listenAddresses defaults to ["*"] and hosts/hp.nix opens port 80 on
      # wlan, which would put a user-writable PHP docroot on the LAN.
      cond = ''
        .hosts | all(.[];
          if .httpdEnabled then .httpdListen == ["127.0.0.1"] else true end)
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
    let
      # The rendered config.lua is exact-match surgery on a vendored file: the
      # repl anchors assert uniqueness, not validity. --validate and luacheck
      # cover the two halves; the CLI arg trap is traps.md 19.
      oxwmHosts = lib.filterAttrs (
        _: h:
        let
          hm = h.config.home-manager.users.${constants.username} or null;
        in
        hm != null && hm ? oxwm
      ) hosts;
      oxwmValidate =
        name: h:
        let
          hm = h.config.home-manager.users.${constants.username};
          cfgLua = hm.xdg.configFile."oxwm/config.lua".source;
          colorFiles = lib.mapAttrsToList (n: _: ''
            printf '%s' ${
              lib.escapeShellArg hm.xdg.configFile."oxwm/colors/${n}.lua".text
            } > "$work/colors/${n}.lua"
          '') hm.oxwm.themes;
          oxwmPkg = h.config.services.xserver.windowManager.oxwm.package;
        in
        ''
          work="$TMPDIR/${name}"
          mkdir -p "$work/colors"
          cp ${cfgLua} "$work/config.lua"
          ${lib.concatStringsSep "\n" colorFiles}
          (cd "$work" && env -u DISPLAY ${oxwmPkg}/bin/oxwm --validate config.lua)
          (cd "$work" && luacheck config.lua --globals oxwm --no-max-line-length)
        '';
    in
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

        oxwm-config =
          pkgs.runCommand "oxwm-config-validate"
            {
              nativeBuildInputs = [ pkgs.luaPackages.luacheck ];
            }
            ''
              set -e
              ${lib.concatStringsSep "\n" (lib.mapAttrsToList oxwmValidate oxwmHosts)}
              touch "$out"
            '';
      };
    };
}
