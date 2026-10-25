{ ... }:
{
  flake.modules.homeManager.shell = { pkgs, ... }: {
    programs.bash = {
      enable = true;
      shellAliases = {
        u = "cd ~/nixos && nix flake update && sudo nixos-rebuild switch --flake ~/nixos#nixos";
        rb = "sudo nixos-rebuild switch --flake ~/nixos#nixos";
        gc = "sudo nix-collect-garbage -d";
        ep = "vis ~/nixos/modules/features/packages.nix";
        ff = "fastfetch";
        opt = "sudo nix store optimise";
      };

      initExtra = ''
        if [[ -f /etc/bashrc ]]; then
          . /etc/bashrc
        fi
        if [[ -n "$KITTY_SHELL_INTEGRATION" && -f "${pkgs.kitty}/lib/kitty/shell-integration/bash/kitty.bash" ]]; then
          . "${pkgs.kitty}/lib/kitty/shell-integration/bash/kitty.bash"
        fi
      '';
    };
  };
}
