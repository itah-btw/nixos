local function palette_slot(name)
  local value = vim.g["base16_gui" .. name]
  if type(value) == "string" and value:match("^#%x%x%x%x%x%x$") then
    return value
  end
  return nil
end

local function lualine_theme()
  local b00 = palette_slot("00")
  local b01 = palette_slot("01")
  local b02 = palette_slot("02")
  local b04 = palette_slot("04")
  local b06 = palette_slot("06")
  local modes = {
    normal = palette_slot("0D"),
    insert = palette_slot("0B"),
    visual = palette_slot("0E"),
    replace = palette_slot("08"),
    command = palette_slot("0A"),
  }

  for _, value in pairs({ b00, b01, b02, b04, b06 }) do
    if value == nil then
      return nil
    end
  end
  for _, value in pairs(modes) do
    if value == nil then
      return nil
    end
  end

  local function mode_section(bg)
    return {
      a = { bg = bg, fg = b00, gui = "bold" },
      b = { bg = b02, fg = b06 },
      c = { bg = b01, fg = b04 },
    }
  end

  return {
    normal = mode_section(modes.normal),
    insert = mode_section(modes.insert),
    visual = mode_section(modes.visual),
    replace = mode_section(modes.replace),
    command = mode_section(modes.command),
    inactive = {
      a = { bg = b01, fg = b04, gui = "bold" },
      b = { bg = b01, fg = b04 },
      c = { bg = b01, fg = b04 },
    },
  }
end

local function apply_lualine()
  local ok, lualine = pcall(require, "lualine")
  if not ok or not lualine.get_config then
    return false
  end
  local theme = lualine_theme()
  if theme == nil then
    return false
  end
  local current = lualine.get_config()
  current.options.theme = theme
  pcall(lualine.setup, current)
  return true
end

local function sync()
  local ok, matugen = pcall(require, "matugen")
  if ok and matugen then
    pcall(matugen.setup)
  end
  apply_lualine()
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("NoctaliaColors", { clear = true }),
  callback = function()
    sync()
    local signal = vim.uv.new_signal()
    _G.__matugen_signal = signal
    signal:start(
      "sigusr1",
      vim.schedule_wrap(function()
        package.loaded["matugen"] = nil
        sync()
      end)
    )
  end,
})

vim.api.nvim_create_user_command("NoctaliaTheme", sync, {
  desc = "Re-sync editor colors with Noctalia palette",
})
