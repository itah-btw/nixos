-- <leader>fc greps the basename; <leader>fi opens a picker rooted at the flake.
-- The token is substituted by modules/nvf.nix, the only place that knows the root.
local ok, builtin = pcall(require, "telescope.builtin")
if ok then
  vim.keymap.set("n", "<leader>fc", function()
    builtin.grep_string({ search = vim.fn.expand("%:t:r") })
  end, { desc = "Grep file basename" })
  vim.keymap.set("n", "<leader>fi", function()
    builtin.find_files({ cwd = "@@CONFIG_ROOT@@" })
  end, { desc = "Find in nixos config" })
end
