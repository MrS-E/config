-- Show relative line numbers
vim.wo.relativenumber = true
vim.o.cursorline = true
vim.o.cursorlineopt = "both"
vim.opt.showmode = false

-- 4 space indenting
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

-- Some undo related stuff
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.nvim/undodir"
vim.opt.undofile = true

-- Search highlighting behavior
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Good colors
vim.opt.termguicolors = true

-- Keep space above and below when scrolling
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

-- vim.cmd("colorscheme catppuccin-macchiato")
