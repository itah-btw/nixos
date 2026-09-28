# Policy guards, run by `nix flake check`. One jq predicate per rule over a
# single JSON blob of the whole flake, so one build reports every failure. Rules
# are `all(.[]; ...)` over the per-host facts: repeated per host, a rule for a
# one-host feature is vacuous on the other and still costs a build.
{
  config,
  lib,
  ...
}:
let
  hosts = config.flake.nixosConfigurations;
  constants = config.flake.constants;

  # US separates name from condition, RS separates records. Neither can occur in a
  # rule, which is what keeps multi-line jq programs intact.
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
      umbrielKeybinds = if hm != null then (hm.programs.umbriel.settings.keybinds or { }) else { };
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
    # A name in both namespaces collapses to one entry above, so the union
    # comparison cannot see a host that wired one side only. dual-namespace-wired.
    dual = builtins.sort builtins.lessThan (
      lib.filter (n: builtins.hasAttr n config.flake.homeManagerModules) (
        builtins.attrNames config.flake.nixosModules
      )
    );
    perHost = lib.mapAttrs (_: h: {
      nixos = names h.nixos;
      home = names h.home;
    }) config.flake.hostModules;
    # Derived, not hand-maintained: wired by more than one host. tv-prefix's input.
    shared = names (
      lib.filter (
        n:
        lib.length (
          lib.filter (h: lib.elem n (h.nixos ++ h.home)) (builtins.attrValues config.flake.hostModules)
        ) > 1
      ) (lib.concatMap (h: h.nixos ++ h.home) (builtins.attrValues config.flake.hostModules))
    );
  };

  # The Lua in nvim/ is data, not a module, so modules-wired cannot see it. A .lua
  # nobody reads is dead; readDir maps names to bare strings, so attrNames first.
  nvimLuaNames = lib.filter (name: lib.hasSuffix ".lua" name) (
    builtins.attrNames (builtins.readDir ../nvim)
  );

  nvimLua = {
    onDisk = builtins.sort builtins.lessThan (map (n: lib.removeSuffix ".lua" n) nvimLuaNames);
    # The cp arguments in neovim.nix. plugin-list.lua is the overlay, the other
    # two are copied into after/plugin/.
    wired = [
      "noctalia-colors"
      "plugin-list"
      "tony-osc52"
    ];
    # A hex here is the palette written down twice.
    withHex = builtins.sort builtins.lessThan (
      lib.filter (
        name: builtins.match ".*#[0-9a-fA-F]{6}.*" (builtins.readFile ../nvim/${name}) != null
      ) nvimLuaNames
    );
  };

  # A typo here would evaluate to "" and silently blank out a value.
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
      # Both ways: an unreferenced module is dead, an unknown name fails later.
      cond = "(.wiring.defined - .wiring.declared) == [] and (.wiring.declared - .wiring.defined) == []";
    }
    {
      name = "dual-namespace-wired";
      # Half-wiring a dual module satisfies modules-wired. "Present means both
      # halves" -- not "every dual module in both lists", which would reject a
      # host needing just the nixos half.
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
      # No directory namespace, so a tv-only module's NAME has to say so. Found
      # hdd.nix (tv-only, unprefixed) on its first run.
      cond = ''
        .wiring as $w
        | def isTv: startswith("tv-");
          def wired($h): $h.nixos + $h.home;
          def unprefixedUnshared: (isTv | not) and (. as $n | $w.shared | index($n) == null);
          def onTv: [ wired($w.perHost.tv)[] | select(unprefixedUnshared) ] | length;
          # No exemption for a shared one: the prefix is a promise about the
          # name, and a name that reaches hp is not TV-only whatever else uses it.
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
    {
      name = "umbriel-repeat-trap";
      # A string form resets repeat to true, so holding Mod+Q closed every window
      # focus landed on. A chord deleted from umbriel.nix passes on purpose: this
      # is about how a chord is written, not that it exists.
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
      # The palette lives in matugen.lua, which Noctalia writes at runtime.
      cond = ".nvimLua.withHex == []";
    }
  ];

  facts = {
    inherit wiring nvimLua;
    constants = builtins.attrNames constants;
    hosts = lib.listToAttrs (map (n: lib.nameValuePair n (factsFor n)) (builtins.attrNames hosts));
  };

  # An unread fact still costs eval on every check. Nix-side, not a rule: no jq
  # program can see the other rules' text.
  unusedFacts = lib.filter (k: !lib.any (r: lib.hasInfix ".${k}" r.cond) rules) (
    builtins.attrNames facts
  );

  blob =
    assert
      unusedFacts == [ ]
      || builtins.trace "flake-policy: facts no rule reads: ${builtins.toJSON unusedFacts}" true;
    builtins.toJSON facts;
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        # Per-rule verdict, all failures together.
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
