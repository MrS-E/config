return {
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason.nvim",
      -- optional but handy: auto-install the needed tools
      "WhoIsSethDaniel/mason-tool-installer.nvim",

      -- debugging UI (optional but recommended)
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function()
      -- Auto-install jdtls + java debug + test (optional)
      local ok = pcall(require, "mason-tool-installer")
      if ok then
        require("mason-tool-installer").setup({
          ensure_installed = {
            "jdtls",
            "java-debug-adapter",
            "java-test",
          },
          run_on_start = true,
        })
      end
    end,
  },
}

