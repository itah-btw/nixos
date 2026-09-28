# Packages only hp needs -- the other half of the axis is shared-packages.nix.
{
  flake.nixosModules.hp-packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      python3
      kdePackages.kdeconnect-kde
    ];
  };
}
