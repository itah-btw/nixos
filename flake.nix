{
  description = "Two NixOS hosts (hp: oxwm/X11, tv: Plasma Bigscreen) + Home Manager; dendritic";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # `cachix` branch hits the pre-built binary cache. Do NOT add
    # `inputs.nixpkgs.follows` here: it breaks cachix.
    # (noctalia inputs removed with the umbriel/noctalia stack)

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # Without this the tv builds against a second, older home-manager.
        home-manager.follows = "home-manager";
      };
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # directory groups, it never namespaces. hosts/*.nix compose.
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    tony-nvim = {
      url = "github:tonybanters/nvim/086d1b30e08b66de250c29792278a0a39b07aa99";
      flake = false;
    };

    oxwm-config = {
      url = "github:tonybanters/oxwm-config";
      flake = false;
    };

    # Local dir, not a repo: wallpapers deploy into the store from here.
    oxwm-wallpapers = {
      url = "path:/home/itah/Projects/oxwm-themes";
      flake = false;
    };
  };

  # No nixConfig binary cache: the noctalia cachix went away with that stack.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
