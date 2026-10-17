{ lib, ... }:
let
  mkField = type: default: lib.mkOption { inherit type default; };
  # config.flake: see the nixos skill's traps 2 and 3 before moving it.
  mkHost =
    {
      inputs,
      config,
      name,
      wiring,
      stateVersion,
      hardware,
      # Home Manager tracks its own release here, independent of the NixOS
      # `stateVersion` below; the two move separately.
      hmStateVersion ? "26.11",
      # Every host carries site overrides, so there is no default to fall back to.
      extra,
    }:
    let
      constants = config.flake.constants;
    in
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs constants; };
      modules = [
        hardware
        inputs.home-manager.nixosModules.home-manager
        (_: {
          networking.hostName = name;
          system.stateVersion = stateVersion;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs constants; };
            users.${constants.username} = {
              home.stateVersion = hmStateVersion;
              imports = map (n: config.flake.homeManagerModules.${n}) wiring.home;
            };
          };
        })
      ]
      ++ [ extra ]
      ++ map (n: config.flake.nixosModules.${n}) wiring.nixos;
    };
in
{
  config._module.args.mkHost = mkHost;

  # Single source of truth for values shared across modules. Typed per field
  # so a rename or wrong-typed override fails at eval, not at use site.
  options.flake.constants = lib.mkOption {
    type = lib.types.submodule {
      options = {
        username = mkField lib.types.str "itah";
        root = mkField lib.types.str "/etc/nixos";
        layout = mkField lib.types.str "us";
        timeZone = mkField lib.types.str "Asia/Jakarta";
        locale = mkField lib.types.str "en_US.UTF-8";
        wlanIface = mkField lib.types.str "wlan0";
        localsendPort = mkField lib.types.port 53317;
        mdnsPort = mkField lib.types.port 5353;
        cursorTheme = mkField lib.types.str "Adwaita";
        cursorSize = mkField lib.types.ints.unsigned 24;
        sansFont = mkField lib.types.str "Inter";
        monoFont = mkField lib.types.str "JetBrainsMono Nerd Font";
        generationKeep = mkField lib.types.ints.positive 5;
      };
    };
    default = { };
    description = "Single source of truth for values shared across modules.";
  };

  # the declaration IS the wiring that checks.nix asserts.
  options.flake.hostModules = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          nixos = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
          home = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      }
    );
    default = { };
    description = "Per-host list of module names, composed by modules/hosts/*.nix.";
  };

  options.flake.homeManagerModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = "Home Manager modules, one per feature, composed by name in modules/hosts/*.nix.";
  };
}
