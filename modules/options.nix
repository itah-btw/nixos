# "unknown flake output"; expected. A leading `_` does NOT silence that --
{ lib, ... }:
let
  # config.flake: see the nixos skill's traps 9 and 10 before moving it.
  mkHost =
    {
      inputs,
      config,
      name,
      wiring,
      stateVersion,
      hardware,
      nixosImports ? [ ],
      hmImports ? [ ],
      extra ? { },
    }:
    let
      constants = config.flake.constants;
    in
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs constants; };
      modules = [
        hardware
      ]
      ++ nixosImports
      ++ [
        inputs.home-manager.nixosModules.home-manager
        (_: {
          networking.hostName = name;
          system.stateVersion = stateVersion;

          home-manager = config.flake.hmDefaults // {
            extraSpecialArgs = { inherit inputs constants; };
            users.${constants.username}.imports =
              hmImports ++ map (n: config.flake.homeManagerModules.${n}) wiring.home;
          };
        })
      ]
      ++ lib.optionals (extra != { }) [ extra ]
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
      ]
    );
    default = {
      username = "itah";
      root = "/etc/nixos";
      layout = "us";
      timeZone = "Asia/Jakarta";
      locale = "en_US.UTF-8";
      tvAddress = "192.168.0.62";
      stateVersion = "26.11";
      wlanIface = "wlan0";
      lanIface = "enp2s0";
      localsendPort = 53317;
      mdnsPort = 5353;
      sshPort = 22;
      tvOutput = "HDMI-A-1";
      tvMode = "1920x1080@60";
      tvRate = 60;
      mediaMount = "/mnt/media";
      mediaLabel = "hdd";
      cursorTheme = "Bibata-Modern-Ice";
      cursorSize = 24;
      sansFont = "Inter";
      monoFont = "JetBrainsMono Nerd Font";
      generationKeep = 5;
      sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaw6LDDl480KBPXmmDpcy0jlMWMZFHCw635SvaH4HA3 itah@hp-nixos";
    };
    description = "Single source of truth for values shared across modules.";
  };

  options.flake.hmDefaults = lib.mkOption {
    type = lib.types.attrs;
    default = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
    };
    description = "Home Manager options shared by every host.";
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
