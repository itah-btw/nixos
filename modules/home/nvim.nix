{
  flake.homeManagerModules.nvim =
    { inputs, ... }:
    {
      programs.neovim.enable = true;

      # Whole upstream repo is the config; manage.lua git-clones its
      # plugins on first launch, so that run needs network + git.
      xdg.configFile."nvim" = {
        source = inputs."tony-nvim";
        # Link contents individually so the entries below can join the tree;
        # a plain directory symlink would collide with them.
        recursive = true;
      };

      # nil asks per buffer whether to archive missing flake inputs.
      xdg.configFile."nvim/after/plugin/nil-lsp.lua".text = ''
        vim.lsp.config("nil_ls", {
          settings = {
            ["nil"] = {
              nix = { flake = { autoArchive = true } },
            },
          },
        })
      '';

      # Same clone-and-rtp shape as manage.lua. matugen.lua is rendered by
      # `oxt` from the active oxwm palette (base16 + lualine); absent until
      # the first switch, in which case the upstream default theme stands.
      xdg.configFile."nvim/after/plugin/oxwm-base16.lua".text = ''
        local plug_dir = vim.fn.stdpath("data") .. "/plugins"
        local path = plug_dir .. "/base16-nvim"
        if not vim.uv.fs_stat(path) then
          vim.fn.mkdir(plug_dir, "p")
          vim.fn.system({ "git", "clone", "--depth=1", "https://github.com/RRethy/base16-nvim", path })
        end
        vim.opt.rtp:prepend(path)
        package.path = package.path .. ";" .. path .. "/lua/?.lua;" .. path .. "/lua/?/init.lua"
        local ok, matugen = pcall(require, "matugen")
        if ok then matugen.setup() end
        -- one-liners.lua pins lualine to tokyonight and sorts after this
        -- file, so re-apply the oxwm theme once startup is complete.
        vim.api.nvim_create_autocmd("VimEnter", {
          once = true,
          callback = function()
            local ok_m, m = pcall(require, "matugen")
            if not ok_m or not m.lualine then return end
            local ok_l, lualine = pcall(require, "lualine")
            if ok_l then lualine.setup({ options = { theme = m.lualine } }) end
          end,
        })
      '';

      home.file.".vim/undodir/.keep".text = "";
    };
}
