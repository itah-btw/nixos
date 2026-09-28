# Neovim via nvf (NotAShelf/nvf), replicating tonybanters/nvim.
{
  flake.homeManagerModules.nvf =
    {
      config,
      constants,
      pkgs,
      ...
    }:
    let
      # Real files, not Nix strings, so stylua can format them and treefmt parse them.
      readLua = name: builtins.readFile ../nvf/${name}.lua;

      # @@CONFIG_ROOT@@ stays inside a literal so the .lua is still valid Lua.
      readLuaAtConfigRoot =
        name: builtins.replaceStrings [ "@@CONFIG_ROOT@@" ] [ constants.root ] (readLua name);
    in
    {
      # The template writes ~/.config/nvim/lua/matugen.lua, but the nvf binary runs
      # with NVIM_APPNAME=nvf (rtp: ~/.config/nvf), so mirror it out of store.
      home.file.".config/nvf/lua/matugen.lua".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nvim/lua/matugen.lua";

      programs.nvf = {
        enable = true;
        defaultEditor = true;
        settings.vim = {
          vimAlias = true;
          viAlias = false;

          globals.mapleader = " ";

          lineNumberMode = "relNumber";
          searchCase = "smart";
          preventJunkFiles = true;
          undoFile.enable = true;
          options = {
            tabstop = 4;
            shiftwidth = 4;
            expandtab = true;
            autoindent = true;
            termguicolors = true;
            background = "dark";
            signcolumn = "yes";
            cursorline = true;
            colorcolumn = "80";
            backspace = "indent,eol,start";
            splitbelow = true;
            splitright = true;
            scrolloff = 8;
            incsearch = true;
            updatetime = 50;
          };

          clipboard = {
            enable = true;
            registers = "unnamedplus";
            providers.wl-copy.enable = true;
          };

          # Single source of the palette; noctalia-colors.lua reads these back out
          # of vim.g.base16_gui00..0F. nvf-palette-nix-only guards a second copy.
          theme = {
            enable = true;
            name = "base16";
            base16-colors = {
              base00 = "#1a1b26";
              base01 = "#16161e";
              base02 = "#2f3549";
              base03 = "#545c7e";
              base04 = "#a9b1d6";
              base05 = "#c0caf5";
              base06 = "#c0caf5";
              base07 = "#ffffff";
              base08 = "#f7768e";
              base09 = "#ff9e64";
              base0A = "#e0af68";
              base0B = "#9ece6a";
              base0C = "#7dcfff";
              base0D = "#7aa2f7";
              base0E = "#bb9af7";
              base0F = "#db4b4b";
            };
          };

          statusline.lualine.enable = true;
          visuals.nvim-web-devicons.enable = true;
          utility.ccc.enable = true;
          utility.undotree.enable = true;

          # vim-fugitive, gitsigns, hunk-nvim, git-conflict, gitlinker-nvim and
          # octo-nvim all default to config.vim.git.enable, so naming them here
          # restated the framework's own derivation.
          git.enable = true;

          telescope.enable = true;

          navigation.harpoon = {
            enable = true;
            mappings = {
              markFile = "<leader>a";
              listMarks = "<C-e>";
            };
          };

          treesitter = {
            enable = true;
            context.enable = true;
          };

          autocomplete.blink-cmp.enable = true;
          # blink-cmp brings its own signature help; nvf's lsp-signature asserts
          # against blink.cmp, so it stays off.
          autocomplete.blink-cmp.setupOpts.signature.enabled = true;
          autopairs.nvim-autopairs.enable = true;
          comments.comment-nvim.enable = true;

          terminal.toggleterm = {
            enable = true;
            # <leader>ft is nvf's Telescope picker; a mapping here is merged, not
            # substituted, and lz.n takes the later of two identical chords with
            # no diagnostic. <leader>tt is free.
            mappings.open = "<leader>tt";
          };

          lsp = {
            enable = true;
            formatOnSave = true;
            lightbulb.enable = true;
            trouble.enable = true;
            lspSignature.enable = false;
          };

          formatter.conform-nvim.enable = true;

          debugger.nvim-dap = {
            enable = true;
            ui.enable = true;
          };

          languages = {
            enableTreesitter = true;
            enableFormat = true;
            enableExtraDiagnostics = true;
            enableDAP = true;

            clang = {
              enable = true;
              cHeader = true;
              lsp.servers = [ "clangd" ];
              format.type = [ "clang-format" ];
              dap.debugger = [ "lldb" ];
              extraDiagnostics.enable = true;
            };
            cmake.enable = true;
            make.enable = true;

            nix.enable = true;
            lua.enable = true;
            rust.enable = true;
            go.enable = true;
            python.enable = true;
            tsx.enable = true;
            typescript.enable = true;
            css.enable = true;
            html.enable = true;
            json.enable = true;
            yaml.enable = true;
            markdown.enable = true;
            bash.enable = true;
            zig.enable = true;
            php.enable = true;
          };

          # nvf merges these in and binds the later of two identical chords with
          # no diagnostic, so nvf keeps a colliding chord and the mapping moved:
          # <leader>co copen -> cq, <leader>fg git_files -> gf, <leader>fs
          # grep_string -> fw. <C-j>/<C-k> went: dupes of <leader>cn/cp.
          keymaps = [
            {
              key = "<leader>cd";
              mode = "n";
              action = "q/";
              desc = "Command line";
            }
            {
              key = "J";
              mode = "v";
              action = ":m '>+1<CR>gv=gv";
            }
            {
              key = "K";
              mode = "v";
              action = ":m '<-2<CR>gv=gv";
            }
            {
              key = "J";
              mode = "n";
              action = "mzJ`z";
            }
            {
              key = "<C-d>";
              mode = "n";
              action = "<C-d>zz";
            }
            {
              key = "<C-u>";
              mode = "n";
              action = "<C-u>zz";
            }
            {
              key = "n";
              mode = "n";
              action = "nzzzv";
            }
            {
              key = "N";
              mode = "n";
              action = "Nzzzv";
            }
            {
              key = "<leader>p";
              mode = "x";
              action = "\"_dP";
            }
            {
              key = "<leader>d";
              mode = [
                "n"
                "v"
              ];
              action = "\"_d";
            }
            {
              key = "<C-c>";
              mode = "i";
              action = "<Esc>";
            }
            {
              key = "Q";
              mode = "n";
              action = "<nop>";
            }
            {
              key = "<leader>k";
              mode = "n";
              action = "<cmd>lnext<CR>zz";
            }
            {
              key = "<leader>j";
              mode = "n";
              action = "<cmd>lprev<CR>zz";
            }
            {
              key = "<leader>cl";
              mode = "n";
              action = ":cclose<CR>";
              silent = true;
            }
            {
              key = "<leader>cq";
              mode = "n";
              action = ":copen<CR>";
              silent = true;
            }
            {
              key = "<leader>cn";
              mode = "n";
              action = ":cnext<CR>zz";
            }
            {
              key = "<leader>cp";
              mode = "n";
              action = ":cprev<CR>";
            }
            {
              key = "<leader>li";
              mode = "n";
              action = ":checkhealth vim.lsp<CR>";
              desc = "LSP Info";
            }
            {
              key = "<leader>cc";
              mode = "n";
              action = "<cmd>!php-cs-fixer fix % --using-cache=no<cr>";
            }
            {
              key = "<leader>s";
              mode = "n";
              action = ":s/\\<<C-r><C-w>\\>//gI<Left><Left><Left>";
            }
            {
              key = "<leader>x";
              mode = "n";
              action = "<cmd>!chmod +x %<CR>";
              silent = true;
            }
            {
              key = "<leader>y";
              mode = [
                "n"
                "v"
              ];
              action = "\"+y";
              desc = "Yank to clipboard";
            }
            {
              key = "<leader>u";
              mode = "n";
              action = ":UndotreeToggle<CR>";
              desc = "Toggle Undotree";
            }
            {
              key = "<leader>mm";
              mode = "n";
              action = "<cmd>make<CR>";
              desc = "Run make";
            }
            {
              key = "<leader><leader>";
              mode = "n";
              action = ":so<CR>";
              desc = "Source file";
            }
            {
              key = "<esc><esc>";
              mode = "t";
              action = "<c-\\><c-n>";
              desc = "Exit terminal mode";
            }

            {
              key = "<leader>gf";
              mode = "n";
              action = ":Telescope git_files<CR>";
              desc = "Find git files";
            }
            {
              key = "<leader>fo";
              mode = "n";
              action = ":Telescope oldfiles<CR>";
              desc = "Recent files";
            }
            {
              key = "<leader>fq";
              mode = "n";
              action = ":Telescope quickfix<CR>";
              desc = "Quickfix";
            }
            {
              key = "<leader>fw";
              mode = "n";
              action = ":Telescope grep_string<CR>";
              desc = "Grep string";
            }
            {
              key = "<leader>fm";
              mode = "n";
              action = ":Telescope man_pages<CR>";
              desc = "Man pages";
            }

            {
              key = "<C-p>";
              mode = "n";
              action = ":lua require('harpoon'):list():prev()<CR>";
              desc = "Harpoon prev";
            }
            {
              key = "<C-n>";
              mode = "n";
              action = ":lua require('harpoon'):list():next()<CR>";
              desc = "Harpoon next";
            }

            {
              key = "K";
              mode = "n";
              action = ":lua vim.lsp.buf.hover()<CR>";
            }
            {
              key = "gd";
              mode = "n";
              action = ":lua vim.lsp.buf.definition()<CR>";
            }
            {
              key = "gD";
              mode = "n";
              action = ":lua vim.lsp.buf.declaration()<CR>";
            }
            {
              key = "gi";
              mode = "n";
              action = ":lua vim.lsp.buf.implementation()<CR>";
            }
            {
              key = "go";
              mode = "n";
              action = ":lua vim.lsp.buf.type_definition()<CR>";
            }
            {
              key = "gr";
              mode = "n";
              action = ":lua vim.lsp.buf.references()<CR>";
            }
            {
              key = "gs";
              mode = "n";
              action = ":lua vim.lsp.buf.signature_help()<CR>";
            }
            {
              key = "gl";
              mode = "n";
              action = ":lua vim.diagnostic.open_float()<CR>";
            }
            {
              key = "<F2>";
              mode = "n";
              action = ":lua vim.lsp.buf.rename()<CR>";
            }
            {
              key = "<F3>";
              mode = [
                "n"
                "x"
              ];
              action = ":lua vim.lsp.buf.format({async=true})<CR>";
            }
            {
              key = "<F4>";
              mode = "n";
              action = ":lua vim.lsp.buf.code_action()<CR>";
            }
          ];

          luaConfigRC = {
            # iskeyword += - so dw/ciw treat hyphenated words as one word.
            tony-opts = "vim.opt.iskeyword:append('-')";

            tony-osc52 = readLua "tony-osc52";
            tony-diagnostics = readLua "tony-diagnostics";
            tony-docgen = readLua "tony-docgen";
            tony-quickformat = readLua "tony-quickformat";
            tony-harpoon-picker = readLua "tony-harpoon-picker";
            tony-telescope-extras = readLuaAtConfigRoot "tony-telescope-extras";

            # Noctalia live palette -> base16 + lualine, on VimEnter and on every
            # SIGUSR1 (wallpaper change). Manual re-sync: :NoctaliaTheme
            noctalia-colors = readLua "noctalia-colors";
          };
        };
      };

      # Not a C tool, so not in c-toolchain.nix: backs the PHP support above.
      home.packages = [ pkgs.php85Packages.php-cs-fixer ];
    };
}
