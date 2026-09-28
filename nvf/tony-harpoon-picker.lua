-- Harpoon + Telescope picker on <leader>fl.
vim.keymap.set("n", "<leader>fl", function()
  local ok, harpoon = pcall(require, "harpoon")
  if not ok then
    vim.notify("harpoon not available", vim.log.levels.WARN)
    return
  end
  local file_paths = {}
  for _, item in ipairs(harpoon:list().items) do
    table.insert(file_paths, item.value)
  end
  local conf = require("telescope.config").values
  require("telescope.pickers")
    .new(require("telescope.themes").get_ivy({ prompt_title = "Working List" }), {
      finder = require("telescope.finders").new_table({ results = file_paths }),
      previewer = conf.file_previewer({}),
      sorter = conf.generic_sorter({}),
    })
    :find()
end, { desc = "Harpoon list (Telescope)" })
