{
  description = "Two NixOS hosts (hp: Umbriel/Noctalia, tv: Plasma Bigscreen) + Home Manager; dendritic";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # `cachix` branch hits the pre-built binary cache. Do NOT add
    # `inputs.nixpkgs.follows` here: it changes the derivation hash and breaks it.
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

    # nvf: modular Neovim config framework (nvf.nix, hp only).
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # plasma-manager: declarative Plasma settings (tv-home.nix, tv only).
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # treefmt wrapper: `nix fmt` passes plain nixfmt no paths, so it cannot
    # discover files itself.
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dendritic plumbing: every file under ./modules is auto-imported, each
    # defining one feature whose module name matches its filename. The
    # directory groups, it never namespaces. hosts/*.nix compose. See README.md.
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
  };

  # Mirrors modules/nix.nix so a non-flake build also avoids local compiles.
  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # Thin entry point: all logic lives in ./modules.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
