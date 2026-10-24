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

      # Restore NixOS's prompt and bash-completion setup, which HM's bashrc
      # does not source by default.
      initExtra = ''
        if [[ -f /etc/bashrc ]]; then
          . /etc/bashrc
        fi

        # kitty shell integration: lets kitty tell idle bash from a running
        # program, so confirm_os_window_close = 1 only prompts when something
        # (opencode, yazi, ...) is actually running.
        if [[ -n "$KITTY_SHELL_INTEGRATION" && -f "${pkgs.kitty}/lib/kitty/shell-integration/bash/kitty.bash" ]]; then
          . "${pkgs.kitty}/lib/kitty/shell-integration/bash/kitty.bash"
        fi
      '';
      # yazi's `y` wrapper is provided by programs.yazi (enableBashIntegration).
    };
  };
}
