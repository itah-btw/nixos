{ lib, ... }:
let
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

  # read `config.flake.*` from inside a module. checks.nix guards the key set.
  options.flake.constants = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.oneOf [
        lib.types.str
        lib.types.int
        lib.types.bool
      ]
    );
    default = {
      username = "itah";
      root = "/etc/nixos";
      layout = "us";
      timeZone = "Asia/Jakarta";
      locale = "en_US.UTF-8";
      wlanIface = "wlan0";
      localsendPort = 53317;
      mdnsPort = 5353;
      cursorTheme = "Adwaita";
      cursorSize = 24;
      sansFont = "Inter";
      monoFont = "JetBrainsMono Nerd Font";
      generationKeep = 5;
    };
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
