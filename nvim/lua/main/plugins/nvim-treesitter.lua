return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local configs = require("nvim-treesitter.configs")

        configs.setup({
            ensure_installed = { "lua", 'gdscript', 'godot_resource', 'gdshader', "vim", "javascript", "html", "rust", "typescript", "glsl", "wgsl", "java" },
            sync_install = false,
            highlight = { enable = true },
            indent = { enable = true },
        })
    end
}
