-- Tony's list plus base16-nvim, whose base16-colorscheme module is what
-- matugen.lua requires. manage.lua clones every entry at startup.
local plugins = require("tony-plugin-list")

table.insert(plugins, "RRethy/base16-nvim")

return plugins
