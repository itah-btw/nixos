# Packages both hosts need. opencode is here because it drives the tv over ssh.
{
  flake.nixosModules.dev-packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      opencode
    ];
  };
}
