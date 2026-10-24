{
  description = "itah's NixOS configuration";

  inputs = {
    # Pinned to the exact nixpkgs revision this machine already runs
    # (nixos-version: 26.11pre1097682.02c087f3fe67), so switching to the
    # flake does not pull in a system upgrade at the same time.
    nixpkgs.url = "github:NixOS/nixpkgs/02c087f3fe67";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ];
    };
  };
}
