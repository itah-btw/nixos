# Packages BOTH hosts need -- the other half of the axis is hp-packages.nix.
# opencode is here because it drives the tv over ssh.
{
  flake.nixosModules.shared-packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      opencode
    ];
  };
}
