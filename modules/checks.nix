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

  # Text after `marker`, up to the next double quote. null if marker is absent.
  quotedAfter =
    marker: text:
    let
      parts = lib.splitString marker text;
    in
    if builtins.length parts < 2 then
      null
    else
      lib.head (lib.splitString "\"" (lib.head (lib.tail parts)));

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
      mysqlEnabled = cfg.services.mysql.enable or false;
      mysqlWantedBy = cfg.systemd.services.mysql.wantedBy or [ ];
      mediaMountOptions = cfg.fileSystems.${constants.mediaMount}.options or [ ];
      autologinUser = cfg.services.displayManager.sddm.settings.Autologin.User or null;
      sshPasswordAuth = cfg.services.openssh.settings.PasswordAuthentication or null;
      noctaliaSettings = if hmNoctalia != null then hmNoctalia.settings else { };
      customPalettes = if hmNoctalia != null then (hmNoctalia.customPalettes or { }) else { };
      hasNoctalia = hmNoctalia != null && (hmNoctalia.enable or false);
      noctaliaSystemdSystem = cfg.programs.noctalia.systemd.enable or false;
      noctaliaSystemdHome = if hm != null then (hm.programs.noctalia.systemd.enable or false) else false;
      starshipSettings = if hm != null then (hm.programs.starship.settings or { }) else { };
      starshipPresets = if hm != null then (hm.programs.starship.presets or [ ]) else [ ];
      umbrielAutostart =
        if hm != null then (hm.programs.umbriel.settings.general.autostart or null) else null;
      umbrielKeybinds = if hm != null then (hm.programs.umbriel.settings.keybinds or { }) else { };
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

  nvimLuaNames = lib.filter (name: lib.hasSuffix ".lua" name) (
    builtins.attrNames (builtins.readDir ../nvim)
  );

  # `${./../../nvim/NAME.lua}` in home/neovim.nix, split on that path. Deriving this is the
  # whole point: a hand-written `wired` list is a second copy of a fact that
  # already lives in a file.
  nvimLuaWired = lib.filter (n: n != null && n != "" && builtins.match "[A-Za-z0-9_-]+" n != null) (
    map (chunk: lib.head (lib.splitString ".lua" chunk)) (
      lib.tail (lib.splitString "./../../nvim/" (builtins.readFile ./home/neovim.nix))
    )
  );

  # Cut at the first `--` so a commented-out palette cannot trip the guard, and
  # require a quoted hex so only real string literals count.
  stripLuaComments =
    text:
    lib.concatStringsSep "\n" (
      map (line: lib.head (lib.splitString "--" line)) (lib.splitString "\n" text)
    );

  nvimLua = {
    onDisk = builtins.sort builtins.lessThan (map (n: lib.removeSuffix ".lua" n) nvimLuaNames);
    wired = builtins.sort builtins.lessThan (lib.unique nvimLuaWired);
    withHex = builtins.sort builtins.lessThan (
      lib.filter (
        name:
        builtins.match ".*\"[^\"]*#[0-9a-fA-F]{6}[^\"]*\".*" (
          stripLuaComments (builtins.readFile ../nvim/${name})
        ) != null
      ) nvimLuaNames
    );
  };

  expectedConstants = builtins.sort builtins.lessThan [
    "cachixKey"
    "cachixSubstituter"
    "cursorSize"
    "cursorTheme"
    "generationKeep"
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

  cache = {
    substituter = constants.cachixSubstituter;
    key = constants.cachixKey;
  };

  # nixConfig is a static flake attribute, so flake.nix cannot read flake.constants.
  # This is the copy that has to stay honest.
  flakeNix = {
    substituter = quotedAfter "extra-substituters = [ \"" (builtins.readFile ../flake.nix);
    key =
      let
        bare = quotedAfter "noctalia.cachix.org-1:" (builtins.readFile ../flake.nix);
      in
      if bare == null then null else "noctalia.cachix.org-1:${bare}";
  };

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
      name = "constants-intact";
      cond = "(.constants | sort) == ${builtins.toJSON expectedConstants}";
    }
    {
      name = "host-identity";
      cond = ".hosts | to_entries | all(.[]; .value.hostName == .key)";
    }
    {
      name = "single-dm";
      # Not just "exactly one": each host's DM is pinned, so swapping hp to gdm
      # goes red instead of staying green.
      cond = ''
        .hosts | to_entries | all(.[];
          (.key) as $host
          | (.value.displayManagers) as $d
          | ([ $d | to_entries[] | select(.value == true) | .key ]) as $on
          | (if $host == "tv" then "sddm" else "noctalia-greeter" end) as $want
          | ($on | length) == 1 and ($on[0]) == $want)
      '';
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
      cond = ''
        .cache as $c
        | .hosts | all(.[];
          ((.substituters | index($c.substituter)) != null
          and (.trustedKeys | index($c.key)) != null))
      '';
    }
    {
      name = "flake-nix-config-agrees";
      # flake.nix's nixConfig cannot read flake.constants; this is what stops the
      # two copies of the cache URL and key from drifting apart.
      cond = "(.flakeNix.substituter == .cache.substituter) and (.flakeNix.key == .cache.key)";
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
        def ok($h): ($h.autologinUser != null) and ($h.sshPasswordAuth == false);
        .hosts | if has("tv") then ok(.tv) else true end
      '';
    }
    {
      name = "noctalia-theming-runtime";
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
      cond = ".hosts | all(.[]; (.starshipSettings == {}) and (.starshipPresets == []))";
    }
    {
      name = "umbriel-repeat-trap";
      cond = ''
        def noRepeat($host; $chord):
          ($host.umbrielKeybinds[$chord] // null) as $b
          | if $b == null then true
            else (($b | type) == "object" and $b.repeat == false)
            end;
        .hosts | all(.[]; . as $host
          | [ "Mod+Q", "Mod+O", "Mod+Shift+Escape", "Alt+Tab" ]
          | all(.[]; noRepeat($host; .)))
      '';
    }
    {
      name = "nvim-lua-wired";
      cond = "(.nvimLua.onDisk - .nvimLua.wired) == [] and (.nvimLua.wired - .nvimLua.onDisk) == []";
    }
    {
      name = "nvim-palette-not-in-lua";
      cond = ".nvimLua.withHex == []";
    }
  ];

  facts = {
    inherit
      wiring
      nvimLua
      cache
      flakeNix
      ;
    constants = builtins.attrNames constants;
    hosts = lib.listToAttrs (map (n: lib.nameValuePair n (factsFor n)) (builtins.attrNames hosts));
  };

  unusedFacts = lib.filter (k: !lib.any (r: lib.hasInfix ".${k}" r.cond) rules) (
    builtins.attrNames facts
  );

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
