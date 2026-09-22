# System-wide packages. No system neovim: nvf provides nvim (home/nvf.nix).
{ ... }:
{
  flake.nixosModules.system-packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      wget
      python3
      git
      opencode
    ];
  };
}
