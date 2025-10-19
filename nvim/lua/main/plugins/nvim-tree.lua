return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        -- disable netrw
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        -- Enable 24-bit color
        vim.opt.termguicolors = true
        require("nvim-tree").setup({
            filters = {
                dotfiles = false,
            },
            git = {
                enable = true,
                ignore = false,
                timeout = 500
            }
        })

        vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", {
            noremap = true,
            silent = true,
            desc = "Toggle File Explorer"
        })
    end
}
