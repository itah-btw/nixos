_: {
  flake.modules.homeManager.shell =
    { pkgs, lib, config, ... }:
    let
      aliases = {
        nrs = "nh os switch ~/Nixos";
        nrb = "nh os boot ~/Nixos";
        nrt = "nh os test ~/Nixos";
        nru = "nh os switch ~/Nixos --update";
        nrr = "nh os rollback";
        nri = "nh os info";
        ngc = "nh clean all --optimise";
        nep = "nvim ~/Nixos/modules/features/packages.nix";
        ff = "fastfetch";
        oup = "bash ~/Nixos/scripts/update-opencode-proxy.sh";

        cdn = "cd ~/Nixos";
        ".." = "cd ..";
        "..." = "cd ../..";
        nrd = "nh os switch ~/Nixos -n";
        nfu = "cd ~/Nixos && nix flake update";
        nsearch = "nh search";
        ndiff = "nvd diff /run/current-system result";
        nhh = "nh --help";
        cnf = "nvim ~/Nixos/flake.nix";

        lg = "lazygit";
        df = "duf";
        tldr = "tealdeer";
        ntree = "nix-tree";
        nlint = "statix check .";
        ndead = "deadnix .";

        ls = "eza --icons=auto --group-directories-first";
        ll = "eza -lah --icons=auto --group-directories-first --git";
        la = "eza -a --icons=auto --group-directories-first";
        lt = "eza --tree --level=2 --icons=auto";
        cat = "bat --style=plain --paging=never";
        du = "dust";
        ps = "procs";
      };
    in
    {
      home.shellAliases = aliases;

      # A single shell-agnostic helper instead of duplicating the function in
      # bash and fish.
      home.packages = [
        (pkgs.writeShellApplication {
          name = "ncfg";
          runtimeInputs = with pkgs; [
            bat
            fd
            fzf
            neovim
          ];
          text = ''
            file=$(fd --type f --hidden --exclude .git . "$HOME/Nixos" \
              | fzf --preview 'bat --style=plain --color=always {}' --preview-window=right:60%)
            if [ -n "$file" ]; then
              exec nvim "$file"
            fi
          '';
        })
      ];

      programs = {
        zoxide.enable = true;
        fzf.enable = true;
        starship = {
          enable = true;
          # Gruvbox-style powerline layout, but colors come from Noctalia's
          # live `noctalia` palette so the prompt follows the shell theme.
          settings = {
            format = lib.concatStrings [
              "[](peach)"
              "$os"
              "$username"
              "[](bg:yellow fg:peach)"
              "$directory"
              "[](fg:yellow bg:teal)"
              "$git_branch"
              "$git_status"
              "[](fg:teal bg:sapphire)"
              "$c"
              "$rust"
              "$golang"
              "$nodejs"
              "$bun"
              "$php"
              "$java"
              "$kotlin"
              "$haskell"
              "$python"
              "[](fg:sapphire bg:overlay2)"
              "$docker_context"
              "$conda"
              "$pixi"
              "[](fg:overlay2 bg:base)"
              "$time"
              "[ ](fg:base)"
              "$line_break"
              "$character"
            ];
            palette = "noctalia";

            os.disabled = false;
            username = {
              show_always = true;
              style_user = "bg:peach fg:crust";
              style_root = "bg:peach fg:crust";
              format = "[$user ]($style)";
            };
            directory = {
              style = "fg:crust bg:yellow";
              format = "[ $path ]($style)";
              truncation_length = 3;
              truncation_symbol = "…/";
            };
            git_branch = {
              symbol = "";
              style = "bg:teal";
              format = "[[ $symbol $branch ](fg:crust bg:teal)]($style)";
            };
            git_status = {
              style = "bg:teal";
              format = "[[($all_status$ahead_behind )](fg:crust bg:teal)]($style)";
            };
            time = {
              disabled = false;
              style = "bg:base";
              format = "[[  $time ](fg:text bg:base)]($style)";
            };
          };
        };

        git.enable = true;

        direnv = {
          enable = true;
          "nix-direnv".enable = true;
        };

        delta = {
          enable = true;
          enableGitIntegration = true;
        };

        bash = {
          enable = true;
          initExtra = ''
            if [[ -f /etc/bashrc ]]; then
              . /etc/bashrc
            fi
            if [[ -n "$KITTY_SHELL_INTEGRATION" && -f "${pkgs.kitty}/lib/kitty/shell-integration/bash/kitty.bash" ]]; then
              . "${pkgs.kitty}/lib/kitty/shell-integration/bash/kitty.bash"
            fi
          '';
        };

        fish = {
          enable = true;
          interactiveShellInit = ''
            set -g fish_greeting
          '';
        };
      };

      # Starship config must be a real, writable file (not a Nix store symlink)
      # so Noctalia's starship template can inject the live `noctalia` palette.
      home.activation.starshipConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu
        target="${config.xdg.configHome}/starship.toml"
        if [ -L "$target" ]; then
          src="$(${pkgs.coreutils}/bin/readlink -f "$target")"
          ${pkgs.coreutils}/bin/rm -f "$target"
          ${pkgs.coreutils}/bin/cp "$src" "$target"
          ${pkgs.coreutils}/bin/chmod u+w "$target"
        fi
      '';

    };
}
