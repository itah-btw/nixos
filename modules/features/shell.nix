{ ... }:
{
  flake.modules.homeManager.shell = { pkgs, ... }: {
    programs.bash = {
      enable = true;
      shellAliases = {
        u = "cd ~/nixos && nix flake update";
        rb = "sudo nixos-rebuild switch --flake ~/nixos#nixos";
        gc = "sudo nix-collect-garbage -d";
        ep = "vis ~/nixos/modules/features/packages.nix";
        ff = "fastfetch";
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
