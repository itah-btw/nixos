{
  description = "Two NixOS hosts (hp: Umbriel/Noctalia, tv: Plasma Bigscreen) + Home Manager, dendritic";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia shell, pinned to the `cachix` branch so you hit the pre-built
    # binary cache instead of compiling locally. Do NOT add
    # `inputs.nixpkgs.follows` here: per upstream docs it changes the
    # derivation hash and breaks the cache.
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

    # nvf: modular Neovim configuration framework (home/nvf.nix, hp only).
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # plasma-manager: declarative Plasma settings (home/tv.nix, tv only).
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # treefmt wrapper: makes `nix fmt` discover files itself (plain nixfmt
    # cannot -- `nix fmt` passes it no paths).
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dendritic plumbing: every file under ./modules is a flake-parts module,
    # auto-imported. Composition lives in modules/hosts/*.nix and references
    # modules BY NAME, so files can be moved or renamed freely.
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
  };

  # Noctalia binary cache, so a non-flake build still avoids local compiles.
  # Mirrored in modules/core/nix.nix. See:
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
