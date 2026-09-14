{
  description = "NixOS configuration with flakes, Home Manager, and oxwm (no display manager, tty1 autologin)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Dendritic: this entry point only assembles the top-level configuration from
  # the feature modules under config/. No specialArgs are passed to the
  # lower-level NixOS / Home Manager module systems.
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;

    # Auto-import all top-level feature modules under config/, excluding the
    # `default.nix` entry point. Every feature is therefore a module of a
    # single top-level configuration.
    tree = dir:
      lib.concatLists (lib.mapAttrsToList (name: type:
        if type == "directory"
        then tree (dir + "/${name}")
        else if
          type
          == "regular"
          && lib.hasSuffix ".nix" name
          && name != "default.nix"
        then [(import (dir + "/${name}"))]
        else [])
      (builtins.readDir dir));

    top = lib.evalModules {
      modules = [./config/default.nix] ++ tree ./config;
      specialArgs = {inherit inputs;};
    };
  in {
    nixosConfigurations.nixos = top.config.build.nixos;

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
