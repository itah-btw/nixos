{
  description = "NixOS configuration with flakes, Home Manager, and oxwm (no display manager, tty1 autologin)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Single host (nixos), single user (itah): call nixosSystem directly.
  # No dendritic wrapper — the module list below is the whole system.
  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/nixos/hardware-configuration.nix
        ./modules/nixos/nix.nix
        ./modules/nixos/base.nix
        ./modules/nixos/desktop.nix
        ./modules/nixos/apps.nix
        {
          networking.hostName = "nixos";
          system.stateVersion = "26.11";
        }
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-bak";
            users.itah = {imports = [./home/itah];};
          };
        }
      ];
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
