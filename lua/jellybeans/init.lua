local M = {}

M.config = {}

-- overrides the defaults from jellybeans.colors from table give as argument
M.setup = function(options)
  local defaults = require("jellybeans.colors")
  M.config = vim.tbl_deep_extend("force", {}, defaults, options or {})
  M.config.loaded = true
end

-- call setup to ensure defaults are initialized, even if later overridden from
-- init.lua. TODO: It might be better to check on load() if defaults are empty
-- table, rather than calling this twice if user setups the theme with config
-- M.setup()

-- evaluates the color transform functions and combines the colors tables
local get_colors = function()
  if not M.config.loaded then
    M.setup()
  end
  local colors = vim.tbl_deep_extend(
    "force",
    {},
    M.config.default,
    M.config.transformations(M.config.default),
    M.config.my_transformations(M.config.default),
    M.config.colors
  )
  return colors
end

-- maps the colors to highlight groups and expands styles to Neovim's flat format
local form_highlights = function()
  local hi = require("jellybeans.jellybeans")
  local colors = get_colors()
  local highlights = hi.highlights(colors, M.config)
  return highlights
end

-- loads the colorscheme:
-- 1. clears previous hl groups, if any
-- 2. sets two vim variables
-- 3. parses the highlight groups and sets them
M.load = function()
  if vim.g.colors_name then
    vim.cmd("hi clear")
  end

  vim.o.termguicolors = true
  vim.g.colors_name = "jellybeans"

  local highlights = form_highlights()
  M.config.loaded = false

  for k,v in pairs(highlights) do
    vim.api.nvim_set_hl(0, k, v)
  end

end

return M
