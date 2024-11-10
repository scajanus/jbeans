local M = {}
local util = require("jellybeans.util")

local parse_style = function(hl)
  if hl.style then
    hl = vim.tbl_extend("force", hl, hl.style)
    hl.style = nil
  end
  return hl
end

M.highlights = function(c, options)
  local hl = {
    --  ColorColumn =    { fg=nil,       bg=p.bg_mid2 },
    --  Conceal =        { fg=p.azure,   bg=nil },
      CurSearch =      { fg=c.search,      bg=util.lighten(c.bg_search, 5) },
    --  Cursor =         { fg=p.bg,      bg=p.fg },
    CursorColumn =   { link='CursorLine' },
    --  CursorIM =       { link='Cursor' },
    CursorLine =     { fg=nil,       bg=c.bg_cursorline },
    CursorLineFold = { fg=nil,       bg=c.bg_fold },
    CursorLineNr =   { fg=c.cursorlinenr,  bg=nil },
    --  CursorLineSign = { fg=p.bg_mid2, bg=nil },
    DiffAdd =        { fg=nil,       bg=c.bg_green },
    DiffChange =     { fg=nil,       bg=c.bg_blue },
    DiffDelete =     { fg=nil,       bg=c.bg_red },
    DiffText =       { fg=nil,       bg=util.lighten(c.bg_blue, 10) },
    Directory =      { fg=c.directory,   bg=nil },
    --  EndOfBuffer =    { fg=p.bg_mid2, bg=nil },
    ErrorMsg =       { link='Error' },
    --  FloatBorder =    { fg=p.accent,  bg=p.bg_edge },
    --  FloatTitle =     { fg=p.accent,  bg=p.bg_edge, bold = true },
    --  FoldColumn =     { fg=p.bg_mid2, bg=nil },
    Folded =         { fg=util.adjust(c.comment, 0, 0, 7), bg=c.bg_fold },
    IncSearch =      { link='Search' },
    --  lCursor =        { fg=p.bg,      bg=p.fg },
    LineNr =         { fg=c.linenr, bg=nil },
    --  LineNrAbove =    { link='LineNr' },
    --  LineNrBelow =    { link='LineNr' },
    MatchParen =     { fg=c.search,       bg=nil, bold=true },
    ModeMsg =        { fg=util.adjust(c.func, 0, -40, 0),   bg=nil },
    --  MoreMsg =        { fg=p.azure,   bg=nil },
    --  MsgArea =        { link='Normal' },
    --  MsgSeparator =   { fg=p.fg_mid2, bg=p.bg_mid2 },
    NonText =        { fg=c.nontext, bg=nil },
    Normal =         { fg=c.fg,      bg=c.bg },
    --  NormalFloat =    { fg=p.fg,      bg=p.bg_edge },
    --  NormalNC =       { link='Normal' },
    PMenu =          { fg=c.cursorlinenr,      bg=c.bg_cursorline },
    --  PMenuExtra =     { link='PMenu' },
    --  PMenuExtraSel =  { link='PMenuSel' },
    --  PMenuKind =      { link='PMenu' },
    --  PMenuKindSel =   { link='PMenuSel' },
    --  PMenuSbar =      { link='PMenu' },
    PMenuSel =       { fg=c.bg,      bg=c.string,      blend=0 },
    --  PMenuThumb =     { fg=nil,       bg=p.bg_mid2 },
    --  Question =       { fg=p.azure,   bg=nil },
    QuickFixLine =   { fg=c.search,       bg=util.darken(c.bg_search, 5) },
    Search =         { fg=c.search,      bg=c.bg_search },
    SignColumn =     { fg=c.fg_gutter, bg=nil },
    SpecialKey =     { fg=c.cursorlinenr, bg=c.bg_cursorline },
    --  SpellBad =       { fg=nil,       bg=nil,       sp=p.red,    undercurl=true },
    --  SpellCap =       { fg=nil,       bg=nil,       sp=p.cyan,   undercurl=true },
    --  SpellLocal =     { fg=nil,       bg=nil,       sp=p.yellow, undercurl=true },
    --  SpellRare =      { fg=nil,       bg=nil,       sp=p.blue,   undercurl=true },
    StatusLine =     { fg=c.fg,  bg=c.bg, reverse=true },
    StatusLineNC =   { fg=c.fg,  bg=c.bg_visual },
    --Substitute =     { fg=util.adjust(c.search, 180, 0, 0),      bg=util.adjust(c.bg_search, 180, 0, 0) },
    TabLine =        { fg=c.fg,  bg=c.bg_fold },
    TabLineFill =    { link='Tabline' },
    TabLineSel =     { fg=c.fg,  bg=c.bg_cursorline, bold=true },
    --  TermCursor =     { fg=nil,       bg=nil,       reverse=true },
    --  TermCursorNC =   { fg=nil,       bg=nil,       reverse=true },
    Title =          { fg=c.title,  bg=nil, bold=true },
    --  VertSplit =      { fg=p.accent,  bg=nil },
    Visual =         { fg=nil,       bg=c.bg_visual },
    --  VisualNOS =      { fg=nil,       bg=p.bg_mid },
    WarningMsg =     { fg=c.red,  bg=nil },
    --  Whitespace =     { fg=p.bg_mid2, bg=nil },
    WildMenu =       { link='PMenuSel' },
    --  WinBar =         { link='StatusLine' },
    --  WinBarNC =       { link='StatusLineNC' },
    WinSeparator =   { fg=c.fg_gutter,  bg=nil },
    --
    --  -- Standard syntax (affects treesitter,
    --  Boolean =        { link='Constant' },
    --  Character =      { link='Constant' },
    Comment =        { fg=c.comment, bg=nil, style=options.styles.comments },
    Conditional =    { fg=c.keyword },
    Constant =       { fg=c.constant,  bg=nil },
    --  Debug =          { link='Special' },
    --  Define =         { link='PreProc' },
    Delimiter =      { fg=c.punctuation,  bg=nil },
    Error =          { fg=nil,       bg=c.bg_red },
    --  Exception =      { link='Statement' },
    --  Float =          { link='Constant' },
    Function =       { fg=c.func,   bg=nil },
    Identifier =     { fg=c.field,  bg=nil },
    ["@variable"] =     { fg=c.fg,  bg=nil },
    ["@variable.parameter"] =     { fg=c.field,  bg=nil },
    ["@variable.member"] =     { fg=c.field,  bg=nil },
    ["@variable.builtin"] =     { fg=c.variable_builtin,  bg=nil },
    --  Ignore =         { fg=nil,       bg=nil },
    --  Include =        { link='PreProc' },
    Keyword =        { fg=c.keyword },
    ["@keyword"] =   { link='Keyword' },
    ["@keyword.return"] =   { link='Statement' },
    ["@keyword.debug"] =   { link='Statement' },
    ["@keyword.exception"] =   { link='Statement' },
    --  Label =          { link='Statement' },
    --  Macro =          { link='PreProc' },
    Number =         { fg=c.number },
    Operator =       { fg=c.operator,      bg=nil },
    ["@attribute"] =       { fg=c.preproc,      bg=nil }, -- python decorators
    --["@keyword.operator"] =   { link='Conditional' },
    ["@keyword.operator"] =   { fg=c.preproc },
    ["@keyword.function"] =   { fg=c.keyword_function },
    --  PreCondit =      { link='PreProc' },
    PreProc =        { fg=c.preproc,    bg=nil },
    Repeat =         { fg=c.statement },
    Special =        { fg=c.special,    bg=nil },
    --SpecialChar =    { fg=util.darken(c.string, 0.68) },
    SpecialComment = { link='Special' },
    Statement =      { fg=c.statement,       bg=nil, style=options.styles.keywords},
    --  StorageClass =   { link='Type' },
    String =         { fg=c.string,   bg=nil },
    ["@string.documentation"] =         { fg=util.adjust(c.comment, 0, 0, 15),   bg=nil },
    ["@text.literal"] = { fg=util.adjust(c.string, 0, -15, 0),   bg=nil },
    ["@punctuation.bracket"] = { fg=c.punctuation,   bg=nil },
    --  Structure =      { link='Type' },
    --  Tag =            { link='Special' },
    --  Todo =           { fg=p.accent,  bg=p.accent_bg, bold=true },
    Type =           { fg=c.type,      bg=nil },
    --  Typedef =        { link='Type' },
    --
    --  -- Other community standard
    --  Bold =       { fg=nil,      bg=nil, bold=true },
    --  Italic =     { fg=nil,      bg=nil, italic=true },
    --  Underlined = { fg=nil,      bg=nil, underline=true }

    DiagnosticError = { fg=c.red,      bg=nil },
    DiagnosticHint =  { fg=c.yellow,   bg=nil },
    DiagnosticInfo =  { fg=c.blue,   bg=nil },
    DiagnosticOk =    { fg=c.green,  bg=nil },
    DiagnosticWarn =  { fg=c.orange, bg=nil },
    --
    --  DiagnosticUnderlineError = { fg=nil, bg=nil, sp=p.red,    underline=true },
    --  DiagnosticUnderlineHint =  { fg=nil, bg=nil, sp=p.cyan,   underline=true },
    --  DiagnosticUnderlineInfo =  { fg=nil, bg=nil, sp=p.blue,   underline=true },
    --  DiagnosticUnderlineOk =    { fg=nil, bg=nil, sp=p.green,  underline=true },
    --  DiagnosticUnderlineWarn =  { fg=nil, bg=nil, sp=p.yellow, underline=true },
    --
    --  DiagnosticFloatingError = { fg=p.red,    bg=p.bg_edge },
    --  DiagnosticFloatingHint =  { fg=p.cyan,   bg=p.bg_edge },
    --  DiagnosticFloatingInfo =  { fg=p.blue,   bg=p.bg_edge },
    --  DiagnosticFloatingOk =    { fg=p.green,  bg=p.bg_edge },
    --  DiagnosticFloatingWarn =  { fg=p.yellow, bg=p.bg_edge },
    --
    --  DiagnosticVirtualTextError = { link='DiagnosticError' },
    --  DiagnosticVirtualTextWarn =  { link='DiagnosticWarn' },
    --  DiagnosticVirtualTextInfo =  { link='DiagnosticInfo' },
    --  DiagnosticVirtualTextHint =  { link='DiagnosticHint' },
    --  DiagnosticVirtualTextOk =    { link='DiagnosticOk' },
    --
    --  DiagnosticSignError = { link='DiagnosticError' },
    --  DiagnosticSignWarn =  { link='DiagnosticWarn' },
    --  DiagnosticSignInfo =  { link='DiagnosticInfo' },
    --  DiagnosticSignHint =  { link='DiagnosticHint' },
    --  DiagnosticSignOk =    { link='DiagnosticOk' },
    --
    --  DiagnosticDeprecated =  { fg=nil, bg=nil, sp=p.red, strikethrough=true },
    DiagnosticUnnecessary = { fg=c.linenr },
  }
  for k, v in pairs(hl) do
    hl[k] = parse_style(v)
  end
  return hl
end
return M