local util = require("jellybeans.util")

---@class Palette
M.default = {
  bg = "#151515", -- normal background
  fg = "#d7d7d7", -- normal text
  variable = "#d7d7d7", -- variable
  func = "#fad07a", -- functions
  string = "#99ad6a", -- String
  field = "#c6b6ee", -- field
  keyword = "#8197bf", -- keyword
  number = "#cf6a4c", -- constant
  type = "#ffb964", -- type
  search = "#f0e4a0",
  title = "#9bce85",
  foo = "#00ff00"
}
M.styles = {
  comments = { italic = true },
  keywords = { italic = true },
}
M.transformations = function(c)
  return {
  -- foregrounds
  cursorlinenr = util.darken(c.fg, 11.2), -- #b8b8b8
  comment = util.darken(c.fg, 29.5), -- #878787
  nontext = util.darken(c.fg, 32.5), -- #808080
  fg_gutter = util.darken(c.fg, 47.5), -- #605958
  linenr = util.darken(c.fg, 49), -- #575757

  -- backgrounds
  bg_visual = util.lighten(c.bg, 20.1), -- #404040
  bg_fold = util.lighten(c.bg, 10), -- #292929
  bg_cursorline = util.lighten(c.bg, 4), -- #1d1d1d

  -- search background
  bg_search = util.blend(c.bg, c.search, 0.15), -- #36342a

  -- constants and builtins, desaturated
  constant = util.adjust(c.number, 0, -10, -4),
  keyword_function = util.adjust(c.keyword, 0, 6.7, -7.7),
  punctuation = util.blend(c.keyword, c.bg, 0.25),

  -- treesitter constant.builtin, function.builtin and constructor all link to Special
  -- special = "#e1af5a", --util.blend(c.func, c.bg, 0.89), -- #Special #Function
  special = util.adjust(c.func, 0, -10, 0),

--    @parameter         Identifier
--    @field             Identifier
--    @property          Identifier
--    @variable          Identifier
--    @namespace         Identifier
  variable_builtin = "#cc9bf0",

  preproc = "#8fbfdc",
  operator = util.blend(c.fg, c.keyword, 0.00),--0.16
  --type_qualifier = util.darken(c.type, 0.9), -- @type.qualifier
  type_qualifier = util.blend(c.bg, c.type, 0.91), -- @type.qualifier
  statement = c.keyword,
  --bg_search = util.darken(c.search, 0.15),
  directory = "#dad085", --util.lighten(c.func, 0.8),
  parameter = util.blend(c.fg, c.field, 0.74),--0.16
}
end
M.my_transformations = function(c)
  return {}
end
local grey = "#aaaaaa"
M.colors = {
  red = util.adjust(grey, 23, 70, 00),
  orange = util.adjust(grey, 55, 70, 0),
  yellow = util.adjust(grey, 100, 70, 0),
  green = util.adjust(grey, 120, 70, 0),
  blue = util.adjust(grey, 240, 70, 0),
  bg_green = util.adjust(M.default.bg, 143, 60, 20),
  bg_red = util.adjust(M.default.bg, 7, 60, 20),
  bg_yellow = util.adjust(M.default.bg, 65, 50, 20),
  bg_blue = util.adjust(M.default.bg, 240, 50, 20),
}
return M
