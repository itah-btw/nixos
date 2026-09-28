-- C kernel-doc generator on <leader>dg, from the line under the cursor.
local function generate_c_doc(line)
  local stripped = line:gsub("^%s*static%s+", ""):gsub("^%s*inline%s+", ""):gsub("^%s*extern%s+", "")
  local ret, name, params = stripped:match("^%s*([%w_]+%s*%**)%s*([%w_]+)%s*%((.*)%)%s*{?%s*$")
  if not name then
    return nil, "No C function signature found on current line"
  end
  local doc = { "/**", " * " .. name .. "() - " }
  if params and params:match("%S") and not params:match("^%s*void%s*$") then
    for param in params:gmatch("([^,]+)") do
      local pname = param:match("([%w_]+)%s*$") or param:match("%*%s*([%w_]+)") or param:match("([%w_]+)%s*%[")
      if pname then
        table.insert(doc, " * @" .. pname .. ": ")
      end
    end
  end
  table.insert(doc, " *")
  ret = ret and ret:gsub("%s+", " "):gsub("^%s*", ""):gsub("%s*$", "") or ""
  -- The type parsed, so emit it rather than a bare " * Return: ".
  if ret ~= "void" and ret ~= "" then
    table.insert(doc, " * Return: " .. ret)
  end
  table.insert(doc, " */")
  return doc, nil
end

local function tony_generate_doc()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
  local ft = vim.bo[bufnr].filetype
  if ft ~= "c" and ft ~= "cpp" and ft ~= "h" then
    vim.notify("No doc generator for filetype: " .. ft, vim.log.levels.WARN)
    return
  end
  local doc, err = generate_c_doc(line)
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  vim.api.nvim_buf_set_lines(bufnr, row - 1, row - 1, false, doc)
  vim.api.nvim_win_set_cursor(0, { row, #doc[1] })
  vim.cmd("startinsert!")
end

vim.keymap.set("n", "<leader>dg", tony_generate_doc, { desc = "Generate C doc comment" })
