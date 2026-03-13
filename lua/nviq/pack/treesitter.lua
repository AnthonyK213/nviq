local packer = require("nviq.appl.packer")

---------------------------------nvim-treesitter--------------------------------

packer.add {
  src = "https://github.com/nvim-treesitter/nvim-treesitter",
  version = "main",
  data = {
    lazy = false,
    conf = function()
      if vim.fn.executable("tree-sitter") == 1 then
        ---@type string[]?
        local parsers = vim.tbl_get(_G.NVIQ.settings, "ts", "parsers")
        if parsers and #parsers > 0 then
          require("nvim-treesitter").install(parsers)
        end
      end

      require("nviq.appl.treesitter").setup()
    end
  }
}
