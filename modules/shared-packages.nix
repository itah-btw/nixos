{
  flake.nixosModules.shared-packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      opencode
    ];
  };
}
