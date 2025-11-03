" Cyberpunk Scarlet Protocol Adjusted)
" Matches Ghostty palette with red-green diff contrast

hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "cyberpunk_scarlet_protocol_adjusted"
set background=dark
set termguicolors

" ---------- Base ----------
hi Normal        guifg=#e41951 guibg=#101116
hi CursorLine    guibg=#181a21
hi Cursor        guifg=#ffffff guibg=#76ff9f
hi CursorLineNr  guifg=#faf945 guibg=#181a21 gui=bold
hi LineNr        guifg=#686868 guibg=#101116
hi Comment       guifg=#686868 gui=italic
hi Visual        guibg=#c1deff guifg=#000000
hi Search        guibg=#fffc67 guifg=#000000 gui=bold
hi IncSearch     guibg=#ff6e67 guifg=#000000 gui=bold

" ---------- Syntax ----------
hi Constant      guifg=#00c5c7
hi String        guifg=#01dc84
hi Character     guifg=#60fa68
hi Number        guifg=#fffc67
hi Boolean       guifg=#faf945
hi Identifier    guifg=#c930c7
hi Function      guifg=#0271b6
hi Statement     guifg=#faf945 gui=bold
hi Operator      guifg=#e41951
hi Keyword       guifg=#bd35ec gui=bold
hi PreProc       guifg=#0271b6
hi Type          guifg=#60fdff
hi Special       guifg=#ff0051
hi Underlined    guifg=#60fdff gui=underline
hi Todo          guifg=#fffc67 guibg=#181a21 gui=bold

" ---------- Diff ----------
hi DiffAdd       guibg=#012b1e guifg=#60fa68 gui=bold
hi DiffChange    guibg=#2b2b01 guifg=#faf945
hi DiffDelete    guibg=#2b0101 guifg=#ff0051 gui=bold
hi DiffText      guibg=#1e3d2b guifg=#01dc84 gui=bold

" ---------- UI ----------
hi StatusLine    guifg=#ffffff guibg=#181a21 gui=bold
hi StatusLineNC  guifg=#686868 guibg=#181a21
hi VertSplit     guifg=#181a21 guibg=#101116
hi Pmenu         guibg=#181a21 guifg=#c7c7c7
hi PmenuSel      guibg=#ff0051 guifg=#ffffff
hi TabLine       guibg=#181a21 guifg=#888888
hi TabLineSel    guibg=#ff0051 guifg=#ffffff gui=bold
hi TabLineFill   guibg=#101116
hi Title         guifg=#fffc67 gui=bold

