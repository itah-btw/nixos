{
  description = "NixOS host hp (oxwm/X11) + Home Manager; dendritic";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # import-tree groups modules/ by directory only; modules declare their
    # own outputs and hosts/*.nix compose them.
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    tony-nvim = {
      url = "github:tonybanters/nvim/086d1b30e08b66de250c29792278a0a39b07aa99";
      flake = false;
    };

    oxwm-config = {
      url = "github:tonybanters/oxwm-config/7b5ec200f12946bfdd3d8ab249834a935d9f7ddb";
      flake = false;
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
