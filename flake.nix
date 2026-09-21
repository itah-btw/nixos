{
  description = "NixOS (unstable) + Home Manager + Umbriel / Noctalia / Noctalia Greeter (dendritic)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia shell. Pinned to the `cachix` branch so you hit the
    # pre-built binary cache instead of compiling locally.
    # Do NOT add `inputs.nixpkgs.follows` here (per upstream docs it
    # changes the derivation hash and breaks the cache).
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };

    umbriel = {
      url = "github:noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nvf: modular Neovim configuration framework (Home Manager module).
    # Follows nixpkgs so the editor builds against the same package set.
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dendritic plumbing: every file under ./modules is a flake-parts
    # module, auto-imported. Host composition lives in
    # modules/hosts/nixos.nix and references modules BY NAME
    # (config.flake.nixosModules.<name>), so files can be moved/renamed
    # freely without fixing import paths.
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
  };

  # Noctalia binary cache (avoids local compiles). See:
  # https://docs.noctalia.dev/noctalia/getting-started/nixos/
  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # Thin entry point: all logic lives in ./modules (dendritic pattern).
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
