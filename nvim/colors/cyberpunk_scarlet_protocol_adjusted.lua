-- Cyberpunk Scarlet Protocol (Adjusted)
-- Matches Ghostty's adjusted palette with strong red/green diff colors

vim.cmd("hi clear")
vim.o.background = "dark"
vim.g.colors_name = "cyberpunk_scarlet_protocol_adjusted"

local c = {
  bg           = "#101116",
  fg           = "#e41951",
  cursor       = "#76ff9f",
  comment      = "#686868",
  red          = "#ff0051",
  green        = "#01dc84",
  yellow       = "#faf945",
  blue         = "#0271b6",
  magenta      = "#c930c7",
  cyan         = "#00c5c7",
  white        = "#c7c7c7",
  lightgreen   = "#60fa68",
  lightyellow  = "#fffc67",
  lightblue    = "#6871ff",
  black        = "#181a21",
  selection_bg = "#c1deff",
  selection_fg = "#000000",
}

local set = vim.api.nvim_set_hl

-- Core UI
set(0, "Normal",        { fg = c.fg, bg = c.bg })
set(0, "Cursor",        { fg = "#ffffff", bg = c.cursor })
set(0, "CursorLine",    { bg = c.black })
set(0, "CursorLineNr",  { fg = c.yellow, bold = true })
set(0, "LineNr",        { fg = c.comment })
set(0, "Visual",        { bg = c.selection_bg, fg = c.selection_fg })
set(0, "Search",        { bg = c.lightyellow, fg = "#000000" })
set(0, "IncSearch",     { bg = "#ff6e67", fg = "#000000" })

-- Syntax groups
set(0, "Comment",       { fg = c.comment, italic = true })
set(0, "Constant",      { fg = c.cyan })
set(0, "String",        { fg = c.green })
set(0, "Character",     { fg = c.lightgreen })
set(0, "Number",        { fg = c.lightyellow })
set(0, "Boolean",       { fg = c.yellow })
set(0, "Identifier",    { fg = c.magenta })
set(0, "Function",      { fg = c.blue })
set(0, "Statement",     { fg = c.yellow, bold = true })
set(0, "Operator",      { fg = c.fg })
set(0, "PreProc",       { fg = c.blue })
set(0, "Type",          { fg = c.lightblue })
set(0, "Special",       { fg = c.red })
set(0, "Underlined",    { fg = c.cyan, underline = true })
set(0, "Todo",          { fg = c.lightyellow, bg = c.black, bold = true })

-- Diff colors
set(0, "DiffAdd",       { fg = c.lightgreen, bg = "#012b1e", bold = true })
set(0, "DiffChange",    { fg = c.yellow, bg = "#2b2b01" })
set(0, "DiffDelete",    { fg = c.red, bg = "#2b0101", bold = true })
set(0, "DiffText",      { fg = c.green, bg = "#1e3d2b", bold = true })

-- UI components
set(0, "StatusLine",    { fg = "#ffffff", bg = c.black, bold = true })
set(0, "StatusLineNC",  { fg = c.comment, bg = c.black })
set(0, "VertSplit",     { fg = c.black, bg = c.bg })
set(0, "Pmenu",         { bg = c.black, fg = c.white })
set(0, "PmenuSel",      { bg = c.red, fg = "#ffffff" })
set(0, "TabLine",       { bg = c.black, fg = "#888888" })
set(0, "TabLineSel",    { bg = c.red, fg = "#ffffff", bold = true })
set(0, "TabLineFill",   { bg = c.bg })
set(0, "Title",         { fg = c.lightyellow, bold = true })

