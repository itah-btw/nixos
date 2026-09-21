# Neovim via nvf (NotAShelf/nvf), replicating tonybanters/nvim.
#
# Coverage map (tony -> nvf):
#   options.lua/keybinds.lua -> vim.options + vim.keymaps (+ globals.mapleader)
#   tokyonight               -> base16, driven LIVE by the Noctalia palette
#                               (luaConfigRC.noctalia-colors loads the neovim
#                               community template output; baked colors below
#                               are fallback only)
#   lualine                  -> statusline.lualine
#   telescope                -> vim.telescope (+ Tony <leader>f* keymaps)
#   harpoon (harpoon2)       -> navigation.harpoon (+ <leader>fl picker)
#   nvim-cmp/cmp-*           -> completion.nvim-cmp
#   fugitive                 -> git.vim-fugitive (+ gitsigns)
#   undotree                 -> utility.undotree (<leader>u)
#   vim-oscyank (SSH yank)   -> built-in OSC52 clipboard over SSH (<leader>y)
#   nvim-highlight-colors    -> utility.ccc
#   treesitter + tonysitter  -> vim.treesitter (+ context sticky header,
#                               replaces tonycontext.lua)
#   flterm.lua (<leader>ft)  -> terminal.toggleterm
#   lsp.lua (clangd, lua, css, intelephense, ts, zls, nil, rust, go, ...)
#                            -> vim.lsp + vim.languages.*
#   docgen.lua (<leader>dg)  -> luaConfigRC.tony-docgen (kept verbatim intent:
#                               C kernel-doc generator; most valuable for C++)
#   quickformat (<leader>qq) -> luaConfigRC.tony-quickformat
#   C++ everything           -> languages.clang (clangd LSP, clang-format,
#                               clangtidy, lldb DAP) + languages.cmake +
#                               bear/gcc/cmake/ninja/lldb tooling on PATH.
{ ... }:
{
  flake.homeManagerModules.nvf =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      # Noctalia "neovim" template writes ~/.config/nvim/lua/matugen.lua, but
      # the nvf binary runs with NVIM_APPNAME=nvf (rtp: ~/.config/nvf), so the
      # template output is invisible to it. Out-of-store symlink keeps it live:
      # Noctalia rewrites the target in place on every palette change.
      home.file.".config/nvf/lua/matugen.lua".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nvim/lua/matugen.lua";

      programs.nvf = {
        enable = true;
        # EDITOR=nvim (matches home/base.nix session var).
        defaultEditor = true;
        settings.vim = {
          vimAlias = true;
          viAlias = false;

          globals.mapleader = " ";

          # --- Tony options.lua ------------------------------------------------
          lineNumberMode = "relNumber";
          searchCase = "smart";
          preventJunkFiles = true; # swapfile + backup off
          undoFile.enable = true; # persistent undo (Tony: ~/.vim/undodir)
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
            undofile = true;
            incsearch = true;
            updatetime = 50;
            # `iskeyword += -` so dw/diw/ciw treat hyphenated words as one.
            # (nvf renders vim.options as vim.opt; iskeyword append needs lua,
            # so it lives in luaConfigRC.tony-opts below.)
          };

          clipboard = {
            enable = true;
            registers = "unnamedplus"; # Tony: clipboard:append("unnamedplus")
            providers.wl-copy.enable = true;
          };

          # --- Theme: base16 ----------------------------------------------------------
          # Baked fallback palette only. At startup (and live on every
          # wallpaper change) luaConfigRC.noctalia-colors below overrides this
          # with the Noctalia palette (neovim community template ->
          # ~/.config/nvim/lua/matugen.lua + SIGUSR1).
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
          utility.ccc.enable = true; # replaces nvim-highlight-colors
          utility.undotree.enable = true;

          git = {
            enable = true;
            vim-fugitive.enable = true; # Tony: tpope/vim-fugitive
            gitsigns.enable = true;
          };

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
            context.enable = true; # sticky header, replaces tonycontext.lua
          };

          autocomplete.nvim-cmp.enable = true; # Tony: hrsh7th/nvim-cmp stack
          autopairs.nvim-autopairs.enable = true;
          comments.comment-nvim.enable = true;

          terminal.toggleterm = {
            enable = true; # replaces flterm.lua floating terminal
            mappings.open = "<leader>ft";
          };

          lsp = {
            enable = true;
            formatOnSave = true;
            lightbulb.enable = true;
            trouble.enable = true;
            lspSignature.enable = true;
          };

          formatter.conform-nvim.enable = true;

          debugger.nvim-dap = {
            enable = true;
            ui.enable = true;
          };

          # --- Languages ---------------------------------------------------------
          # Tony's LSP set (lua, css, php/intelephense, ts, zig, nix, rust,
          # go, json, haskell) plus the full C/C++ stack.
          languages = {
            enableTreesitter = true;
            enableFormat = true;
            enableExtraDiagnostics = true;
            enableDAP = true;

            clang = {
              enable = true; # C/C++ everything: treesitter, clangd, format, DAP
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
            php.enable = true; # Tony: intelephense
          };

          # --- Tony keybinds (keybinds.lua + after/plugin/*) ----------------------
          keymaps = [
            # netrw explorer
            {
              key = "<leader>cd";
              mode = "n";
              action = ":Ex<CR>";
              desc = "Open Ex";
            }
            # move selected block (Tony: Alt Up/Down in vscode)
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
            # join lines, keep cursor
            {
              key = "J";
              mode = "n";
              action = "mzJ`z";
            }
            # half-page scroll, keep cursor centered
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
            # blackhole paste/delete (don't clobber clipboard)
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
            # quickfix / location navigation, centered
            {
              key = "<C-j>";
              mode = "n";
              action = "<cmd>cnext<CR>zz";
            }
            {
              key = "<C-k>";
              mode = "n";
              action = "<cmd>cprev<CR>zz";
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
              key = "<leader>co";
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
              action = ":cprev<CR>zz";
            }
            {
              key = "<leader>li";
              mode = "n";
              action = ":checkhealth vim.lsp<CR>";
              desc = "LSP Info";
            }
            # PHP lint (Tony: php-cs-fixer)
            {
              key = "<leader>cc";
              mode = "n";
              action = "<cmd>!php-cs-fixer fix % --using-cache=no<cr>";
            }
            # substitute word under cursor (current line)
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
            # yank to system clipboard (SSH-safe via OSC52, see luaConfigRC)
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

            # --- Telescope (Tony <leader>f*) -------------------------------------
            {
              key = "<leader>ff";
              mode = "n";
              action = ":Telescope find_files<CR>";
              desc = "Find files";
            }
            {
              key = "<leader>fg";
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
              key = "<leader>fh";
              mode = "n";
              action = ":Telescope help_tags<CR>";
              desc = "Help tags";
            }
            {
              key = "<leader>fb";
              mode = "n";
              action = ":Telescope buffers<CR>";
              desc = "Buffers";
            }
            {
              key = "<leader>fs";
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

            # --- Harpoon extras (Tony: <C-p>/<C-n> nav, <leader>fl picker) ------
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

            # --- LSP (Tony lsp.lua LspAttach maps) --------------------------------
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

          # --- Custom lua Tony nvf cannot express declaratively -------------------
          luaConfigRC = {
            # iskeyword += - (hyphenated words are one word for dw/ciw)
            tony-opts = "vim.opt.iskeyword:append('-')";

            # SSH-aware clipboard: OSC52 when over SSH, matching vim-oscyank's
            # role in Tony's setup (yank works even on SSH).
            tony-osc52 = ''
              if vim.env.SSH_CONNECTION ~= nil then
                local ok, osc52 = pcall(require, 'vim.ui.clipboard.osc52')
                if ok then
                  vim.g.clipboard = {
                    name = 'OSC 52',
                    copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
                    paste = { ['+'] = osc52.paste('+'), ['*'] = osc52.paste('*') },
                  }
                end
              end
            '';

            # Tony's plugin/docgen.lua: C kernel-doc generator on <leader>dg.
            # (C/C++ focus; Go/Rust/Python variants from the original were
            # dropped — nvf languages already cover those via LSP snippets.)
            tony-docgen = ''
              local function generate_c_doc(bufnr, row, line)
                local stripped = line:gsub("^%s*static%s+", ""):gsub("^%s*inline%s+", ""):gsub("^%s*extern%s+", "")
                local ret, name, params = stripped:match('^%s*([%w_]+%s*%**)%s*([%w_]+)%s*%((.*)%)%s*{?%s*$')
                if not name then return nil, 'No C function signature found on current line' end
                local doc = { '/**', ' * ' .. name .. '() - ' }
                if params and params:match('%S') and not params:match('^%s*void%s*$') then
                  for param in params:gmatch('([^,]+)') do
                    local pname = param:match('([%w_]+)%s*$') or param:match('%*%s*([%w_]+)') or param:match('([%w_]+)%s*%[')
                    if pname then table.insert(doc, ' * @' .. pname .. ': ') end
                  end
                end
                table.insert(doc, ' *')
                ret = ret and ret:gsub("%s+", " "):gsub("^%s*", ""):gsub("%s*$", "") or ""
                if ret ~= "void" and ret ~= "" then table.insert(doc, ' * Return: ') end
                table.insert(doc, ' */')
                return doc, nil
              end
              local function tony_generate_doc()
                local bufnr = vim.api.nvim_get_current_buf()
                local row = vim.api.nvim_win_get_cursor(0)[1]
                local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
                local ft = vim.bo[bufnr].filetype
                if ft ~= 'c' and ft ~= 'cpp' and ft ~= 'h' then
                  vim.notify('No doc generator for filetype: ' .. ft, vim.log.levels.WARN)
                  return
                end
                local doc, err = generate_c_doc(bufnr, row, line)
                if err then vim.notify(err, vim.log.levels.ERROR) return end
                vim.api.nvim_buf_set_lines(bufnr, row - 1, row - 1, false, doc)
                vim.api.nvim_win_set_cursor(0, { row, #doc[1] })
                vim.cmd('startinsert!')
              end
              vim.keymap.set('n', '<leader>dg', tony_generate_doc, { desc = 'Generate C doc comment' })
            '';

            # Tony's plugin/quickformat.lua: explode paren args on <leader>qq.
            tony-quickformat = ''
              local function reformat_parenthesized_content()
                local bufnr = vim.api.nvim_get_current_buf()
                local row = vim.api.nvim_win_get_cursor(0)[1]
                local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
                local inside = line:match('%((.-)%)')
                if not inside then vim.notify('No content found inside parentheses', vim.log.levels.ERROR) return end
                local prefix = line:match("^(.-)%(") or ""
                local suffix = line:match("%)(.*)$") or ""
                local parts = vim.split(inside, ',%s*')
                if #parts == 0 then vim.notify('No comma-separated content found', vim.log.levels.ERROR) return end
                local new_lines = { prefix .. '(' }
                for i, part in ipairs(parts) do
                  if i < #parts then table.insert(new_lines, '        ' .. part .. ',')
                  else table.insert(new_lines, '        ' .. part) end
                end
                table.insert(new_lines, '    )' .. suffix)
                vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, new_lines)
              end
              vim.keymap.set('n', '<leader>qq', reformat_parenthesized_content, { desc = 'Explode paren args' })
            '';

            # Tony's harpoon+Telescope picker on <leader>fl.
            tony-harpoon-picker = ''
              vim.keymap.set('n', '<leader>fl', function()
                local ok, harpoon = pcall(require, 'harpoon')
                if not ok then vim.notify('harpoon not available', vim.log.levels.WARN) return end
                local file_paths = {}
                for _, item in ipairs(harpoon:list().items) do table.insert(file_paths, item.value) end
                local conf = require('telescope.config').values
                require('telescope.pickers').new(require('telescope.themes').get_ivy({ prompt_title = 'Working List' }), {
                  finder = require('telescope.finders').new_table({ results = file_paths }),
                  previewer = conf.file_previewer({}),
                  sorter = conf.generic_sorter({}),
                }):find()
              end, { desc = 'Harpoon list (Telescope)' })
            '';

            # Tony's grep-file-basename (<leader>fc) and config-dir
            # finder (<leader>fi, pointed at this repo).
            tony-telescope-extras = ''
              local ok, builtin = pcall(require, 'telescope.builtin')
              if ok then
                vim.keymap.set('n', '<leader>fc', function()
                  builtin.grep_string({ search = vim.fn.expand('%:t:r') })
                end, { desc = 'Grep file basename' })
                vim.keymap.set('n', '<leader>fi', function()
                  builtin.find_files({ cwd = '/etc/nixos' })
                end, { desc = 'Find in nixos config' })
              end
            '';

            # Tony's lsp.lua diagnostics style (rounded borders, icons).
            tony-diagnostics = ''
              vim.diagnostic.config({
                virtual_text = true,
                severity_sort = true,
                float = { style = "minimal", border = "rounded", source = "if_many", header = "", prefix = "" },
                signs = { text = {
                  [vim.diagnostic.severity.ERROR] = "✘",
                  [vim.diagnostic.severity.WARN] = "▲",
                  [vim.diagnostic.severity.HINT] = "⚑",
                  [vim.diagnostic.severity.INFO] = "»",
                } },
              })
            '';

            # Noctalia live palette -> base16 + lualine, so the powerline
            # follows the wallpaper. The Noctalia "neovim" template rewrites
            # ~/.config/nvim/lua/matugen.lua on every palette change and
            # SIGUSR1s nvim. We load it at startup (over the baked fallback
            # above), rebuild the lualine theme from the base16 globals, and
            # take over the SIGUSR1 handler so changes apply live, no restart.
            # Manual re-sync: :NoctaliaTheme
            noctalia-colors = ''
              local function noctalia_slot(slot, fallback)
                for _, s in ipairs({ slot, slot:lower(), slot:upper() }) do
                  local v = vim.g["base16_gui" .. s]
                  if type(v) == "string" and v:match("^#%x%x%x%x%x%x$") then
                    return v
                  end
                end
                return fallback
              end

              local function noctalia_lualine_theme()
                local b00 = noctalia_slot("00", "#1a1b26")
                local b01 = noctalia_slot("01", "#16161e")
                local b02 = noctalia_slot("02", "#2f3549")
                local b04 = noctalia_slot("04", "#a9b1d6")
                local b05 = noctalia_slot("05", "#c0caf5")
                local b06 = noctalia_slot("06", "#c0caf5")
                local mode_bg = {
                  normal = noctalia_slot("0D", "#7aa2f7"),
                  insert = noctalia_slot("0B", "#9ece6a"),
                  visual = noctalia_slot("0E", "#bb9af7"),
                  replace = noctalia_slot("08", "#f7768e"),
                  command = noctalia_slot("0A", "#e0af68"),
                }
                local function mode_section(bg)
                  return {
                    a = { bg = bg, fg = b00, gui = "bold" },
                    b = { bg = b02, fg = b06 },
                    c = { bg = b01, fg = b04 },
                  }
                end
                return {
                  normal = mode_section(mode_bg.normal),
                  insert = mode_section(mode_bg.insert),
                  visual = mode_section(mode_bg.visual),
                  replace = mode_section(mode_bg.replace),
                  command = mode_section(mode_bg.command),
                  inactive = {
                    a = { bg = b01, fg = b04, gui = "bold" },
                    b = { bg = b01, fg = b04 },
                    c = { bg = b01, fg = b04 },
                  },
                }
              end

              local function noctalia_apply_lualine()
                local ok_ll, lualine = pcall(require, "lualine")
                if not ok_ll or not lualine.get_config then return false end
                local cur = lualine.get_config()
                cur.options.theme = noctalia_lualine_theme()
                pcall(lualine.setup, cur)
                return true
              end

              local function noctalia_sync()
                local ok, matugen = pcall(require, "matugen")
                if ok and matugen then pcall(matugen.setup) end
                noctalia_apply_lualine()
              end

              vim.api.nvim_create_autocmd("VimEnter", {
                group = vim.api.nvim_create_augroup("NoctaliaColors", { clear = true }),
                callback = function()
                  noctalia_sync()
                  if _G.__matugen_signal then
                    pcall(function() _G.__matugen_signal:stop() end)
                    pcall(function() _G.__matugen_signal:close() end)
                  end
                  local sig = vim.uv.new_signal()
                  _G.__matugen_signal = sig
                  sig:start("sigusr1", vim.schedule_wrap(function()
                    package.loaded["matugen"] = nil
                    noctalia_sync()
                  end))
                end,
              })

              vim.api.nvim_create_user_command("NoctaliaTheme", noctalia_sync, { desc = "Re-sync editor colors with Noctalia palette" })
            '';
          };
        };
      };

      # C/C++ toolchain on PATH (complements what nvf installs itself):
      # compilers/build, bear (generates compile_commands.json for clangd),
      # lldb (DAP), cmake-format + clang extra tools.
      home.packages = with pkgs; [
        gcc
        cmake
        ninja
        bear
        lldb
        gersemi
        clang-tools
        cppcheck
        valgrind
      ];
    };
}
