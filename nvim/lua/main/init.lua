require("main.lazy_init")
require("main.settings")
require("main.keymaps")

vim.lsp.config('gdscript', {})
vim.lsp.enable('gdscript')

vim.g.vimtex_view_method = 'skim'
