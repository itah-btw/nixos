{
  flake.homeManagerModules.neovim =
    {
      inputs,
      pkgs,
      ...
    }:
    let
      # The pinned config. lua/manage.lua clones the plugins at runtime, so this
      # pins the config revision only -- see flake.nix.
      tony = inputs."tony-nvim";

      # His tree, with our files layered in. after/plugin/ is sourced after
      # plugin/, so the "local-" names win over his colors.lua and lsp.lua.
      local = pkgs.runCommand "neovim-config" { } ''
        cp -r ${tony} $out
        chmod -R u+w $out
        # nix.so needs libstdc++, which neovim's closure lacks. The other seven
        # match this neovim's ABI, and he ships no treesitter plugin to rebuild with.
        rm -f $out/parser/nix.so
        cp ${./../nvim/tony-osc52.lua} $out/after/plugin/local-osc52.lua
        cp ${./../nvim/noctalia-colors.lua} $out/after/plugin/local-noctalia.lua
        # matugen.lua calls require('base16-colorscheme'), the module RRethy's
        # base16-nvim provides. His list omits it, so extend the list here.
        mv $out/lua/plugin-list.lua $out/lua/tony-plugin-list.lua
        cp ${./../nvim/plugin-list.lua} $out/lua/plugin-list.lua
      '';
    in
    {
      home.packages = [
        pkgs.neovim
        # <leader>cc in his keybinds.lua shells out to it.
        pkgs.php85Packages.php-cs-fixer
      ];

      # His config, ours on top. Linked leaf by leaf rather than as one tree:
      # matugen.lua is Noctalia's output, regenerated on every palette change,
      # so ~/.config/nvim/lua has to stay a real directory it can write into.
      # home.file creates the parent directories, symlinks only the leaves.
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
