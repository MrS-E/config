return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        spec = {
            { "<leader>x", group = "Trouble" },
            { "<leader>f", group = "Telescope" }
        }
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer Local Keymaps (which-key)",
        },
        { "<leader>f", group = "+Telescope" },
        { "<leader>x", group = "+Trouble" }
    },
}
