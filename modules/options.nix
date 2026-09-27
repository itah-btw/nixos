# Flake-private plumbing: wiring table, shared scalars, and the Home Manager
# namespace flake-parts does not ship. `nix flake check` reports all four as
# "unknown flake output"; expected. A leading `_` does NOT silence that --
# flake-parts then resolves the option to nothing.
{ lib, ... }:
{
  # Threaded in via specialArgs / extraSpecialArgs: neither module system can
  # read `config.flake.*` from inside a module. checks.nix guards the key set.
  options.flake.constants = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {
      username = "itah";
      root = "/etc/nixos";
      layout = "us";
      timeZone = "Asia/Jakarta";
      locale = "en_US.UTF-8";
      tvAddress = "192.168.0.62";
    };
    description = "Single source of truth for values shared across modules.";
  };

  # Merged with the per-host parts in modules/hosts/*.nix.
  options.flake.hmDefaults = lib.mkOption {
    type = lib.types.attrs;
    default = {
      useGlobalPkgs = true;
      useUserPackages = true;
      # Move a clobbering file aside rather than failing activation, which
      # would leave the system switched and the home stale.
      backupFileExtension = "hm-backup";
    };
    description = "Home Manager options shared by every host.";
  };

  # Hosts declare their module names here and compose from this same list, so
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
