require("vis")

local function clip(text)
  local p = io.popen("wl-copy", "w")
  p:write(text)
  p:close()
end

local function unclip()
  local p = io.popen("wl-paste --no-newline", "r")
  local text = ""
  if p then
    text = p:read("*a")
    p:close()
  end
  return text
end

vis:operator_new("y", function(file, range, pos)
  local text = file:content(range.start, range.finish - range.start)
  clip(text)
  vis.registers['"'] = { text }
  return pos
end, "Yank to system clipboard")

vis:operator_new("d", function(file, range, pos)
  local text = file:content(range.start, range.finish - range.start)
  clip(text)
  vis.registers['"'] = { text }
  file:delete(range.start, range.finish - range.start)
  return pos
end, "Cut to system clipboard")

local function do_paste(before)
  local file = vis.win.file
  local pos = vis.win.selection.pos
  local text = unclip()
  local at
  if text:sub(-1) == "\n" then
    if before then
      local upto = file:content(0, pos)
      local idx = upto:reverse():find("\n", 1, true)
      at = idx and (pos - idx + 1) or 0
    else
      local rest = file:content(pos, file.size - pos)
      local nl = rest:find("\n", 1, true)
      at = nl and (pos + nl) or file.size
    end
  else
    at = before and pos or pos + 1
  end
  file:insert(at, text)
  return 1
end

vis:map(vis.modes.NORMAL, "p", function()
  return do_paste(false)
end, "Paste from system clipboard")

vis:map(vis.modes.NORMAL, "P", function()
  return do_paste(true)
end, "Paste from system clipboard (before cursor)")

local replace_id = vis:operator_register(function(file, range, pos)
  file:delete(range.start, range.finish - range.start)
  file:insert(range.start, unclip())
  return pos
end)
vis:map(vis.modes.VISUAL, "p", function()
  vis:operator(replace_id)
end, "Replace selection with clipboard")

-- vis 0.9's bundled ftdetect table has no patterns for these, so the files
-- open with the plain-text lexer. `nix` is absent upstream as a *table entry*
-- entirely, not merely as a pattern, so it has to be created rather than
-- appended to -- hence `or {}`.
local extra_ftdetect = {
  nix = { "%.nix$" },
  typescript = { "%.mts$", "%.cts$" },
  html = { "%.vue$", "%.svelte$", "%.astro$" },
  cpp = { "%.H$", "%.inl$", "%.ipp$", "%.tcc$" },
}

for lang, exts in pairs(extra_ftdetect) do
  local ft = vis.ftdetect.filetypes[lang] or { ext = {} }
  ft.ext = ft.ext or {}
  for _, ext in ipairs(exts) do
    table.insert(ft.ext, ext)
  end
  vis.ftdetect.filetypes[lang] = ft
end

-- lspc auto-picks fzf for menu_cmd when it is on PATH, but leaves
-- confirm_cmd on vis-menu; pin both so the picker is uniform.
local lspc = require("plugins/vis-lspc")
if next(lspc) then
  lspc.menu_cmd = "fzf"
  lspc.confirm_cmd = "fzf"

  -- nil is the lighter of the two Nix servers in nixpkgs: nixd evaluates the
  -- flake graph on initialize, nil works per file.
  lspc.ls_map.nix = {
    name = "nil",
    cmd = "nil --stdio",
    roots = { "flake.nix", "flake.lock" },
    formatting_options = { tabSize = 2, insertSpaces = true },
  }

  lspc.ls_map.php = {
    name = "intelephense",
    cmd = "intelephense --stdio",
    roots = { "composer.json", ".php-cs-fixer.php", "phpunit.xml" },
    formatting_options = { tabSize = 4, insertSpaces = true },
  }
end

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
  vis:command("set number")
  vis:command("set relativenumbers")
  vis:command("set cursorline")
  vis:command("set autoindent")
  vis:command("set expandtab")
  vis:command("set tabwidth 4")
  vis:command("set ignorecase")
  vis:command("set colorcolumn 80")
  vis:command("set theme noctalia")
end)
