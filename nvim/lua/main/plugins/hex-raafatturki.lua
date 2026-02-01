return {
  "RaafatTurki/hex.nvim",
  config = function()
    require("hex").setup {
      -- example options (all optional)
      dump_cmd = "xxd -g 1 -u", -- how to dump hex
      assemble_cmd = "xxd -r",  -- how to assemble back
    }
  end,
}

