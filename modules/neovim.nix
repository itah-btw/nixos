{
  flake.homeManagerModules.neovim =
    {
      inputs,
      pkgs,
      ...
    }:
    let
      tony = inputs."tony-nvim";

      local = pkgs.runCommand "neovim-config" { } ''
        cp -r ${tony} $out
        chmod -R u+w $out
        rm -f $out/parser/nix.so
        cp ${./../nvim/tony-osc52.lua} $out/after/plugin/local-osc52.lua
        cp ${./../nvim/noctalia-colors.lua} $out/after/plugin/local-noctalia.lua
        mv $out/lua/plugin-list.lua $out/lua/tony-plugin-list.lua
        cp ${./../nvim/plugin-list.lua} $out/lua/plugin-list.lua
      '';
    in
    {
      home.packages = [
        pkgs.neovim
        pkgs.phpPackages.php-cs-fixer

        (pkgs.writeShellApplication {
          name = "update-plugins";
          runtimeInputs = [ pkgs.git ];
          text = ''
            # manage.lua clones each plugin once, on first start, and never
            dir="''${XDG_DATA_HOME:-$HOME/.local/share}/nvim/plugins"  # manage.lua: stdpath("data")/plugins
            if [ ! -d "$dir" ]; then
              echo "no plugins in $dir; start nvim once so manage.lua clones them" >&2
              exit 1
            fi

            moved=0
            for p in "$dir"/*/; do
              p=''${p%/}
              name=''${p##*/}
              # how manage.lua cloned; these are never edited, so --hard is safe.
              branch=$(git -C "$p" rev-parse --abbrev-ref HEAD) || continue
              if [ -n "$(git -C "$p" status --porcelain)" ]; then
                echo "$name: dirty, skipped -- stash or discard first" >&2
                continue
              fi

              before=$(git -C "$p" rev-parse --short HEAD)
              if git -C "$p" fetch --depth=1 --quiet origin "$branch"; then
                git -C "$p" reset --hard --quiet FETCH_HEAD
              else
                echo "$name: fetch of $branch failed, left at $before" >&2
                continue
              fi

              after=$(git -C "$p" rev-parse --short HEAD)
              if [ "$before" != "$after" ]; then
                moved=$((moved + 1))
                printf '%-14s %s -> %s  (%s)\n' "$name" "$before" "$after" "$branch"
              fi
            done
            echo "$moved updated"
          '';
        })
      ];

      home.file = {
        ".config/nvim/init.lua".source = "${local}/init.lua";
        ".config/nvim/after".source = "${local}/after";
        ".config/nvim/plugin".source = "${local}/plugin";
        ".config/nvim/queries".source = "${local}/queries";
        ".config/nvim/parser".source = "${local}/parser";
        ".config/nvim/lua/config".source = "${local}/lua/config";
        ".config/nvim/lua/manage.lua".source = "${local}/lua/manage.lua";
        ".config/nvim/lua/plugin-list.lua".source = "${local}/lua/plugin-list.lua";
        ".config/nvim/lua/tony-plugin-list.lua".source = "${local}/lua/tony-plugin-list.lua";
      };
    };
}
