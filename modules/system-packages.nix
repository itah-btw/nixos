# hp-only system packages. Shared ones are in dev-packages.nix.
{
  flake.nixosModules.system-packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      python3
      kdePackages.kdeconnect-kde
    ];
  };
}
