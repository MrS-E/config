return {
    'nvimdev/lspsaga.nvim',
    config = function()
        require('lspsaga').setup({
            lightbulb = {
                enable = false
            }
        })
        vim.keymap.set('n', 'K', '<cmd>Lspsaga hover_doc<CR>', {
            silent = true,
            desc = 'Saga hover docs',
        })
    end,
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'nvim-tree/nvim-web-devicons',
    }
}
