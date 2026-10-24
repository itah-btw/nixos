{ ... }:
{
  flake.modules.nixos.packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      kitty
      vis
      wget
      opencode
      wl-clipboard
    ];
  };
}
