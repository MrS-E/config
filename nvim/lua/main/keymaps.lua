-- Easier window navigation
-- vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
-- vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
-- vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
-- vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })
-- Telescope related
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {
    desc = 'Telescope find files'
})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {
    desc = 'Telescope live grep'
})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {
    desc = 'Telescope buffers'
})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {
    desc = 'Telescope help tags'
})

vim.keymap.set('n', '<leader>w', ':set wrap!<CR>', {
    noremap = true, silent = true })

-- GPT Models
-- Both visual and normal mode for each, so you can open with a visual selection or without.
vim.api.nvim_set_keymap('v', '<leader>a', ':GPTModelsCode<CR>', {
    noremap = true
})
vim.api.nvim_set_keymap('n', '<leader>a', ':GPTModelsCode<CR>', {
    noremap = true
})

vim.api.nvim_set_keymap('v', '<leader>c', ':GPTModelsChat<CR>', {
    noremap = true
})
vim.api.nvim_set_keymap('n', '<leader>c', ':GPTModelsChat<CR>', {
    noremap = true
})
