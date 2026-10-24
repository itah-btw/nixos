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
        # yazi wrapper: change cwd to the last visited directory on exit
        function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          yazi "$@" --cwd-file="$tmp"
          IFS= read -r -d ''' cwd < "$tmp"
          [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
          rm -f -- "$tmp"
        }
      '';
    };
  };
}
