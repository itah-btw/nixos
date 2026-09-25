# System-wide packages. No system neovim: nvf provides nvim (home/nvf.nix).
# No wget: curl (home) covers fetching. No unzip/fd/rg: home covers those.
{ ... }:
{
  flake.nixosModules.system-packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      python3
      git
      opencode
      kdePackages.kdeconnect-kde
    ];
  };
}
