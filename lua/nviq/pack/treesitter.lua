local mini_deps = require("mini.deps")

mini_deps.now(function()
  mini_deps.add {
    source = "nvim-treesitter/nvim-treesitter",
    checkout = "main",
  }

  if vim.fn.executable("tree-sitter") == 1 then
    ---@type string[]?
    local parsers = vim.tbl_get(_G.NVIQ.settings, "ts", "parsers")
    if parsers and #parsers > 0 then
      require("nvim-treesitter").install(parsers)
    end
  end

  require("nviq.appl.treesitter").setup()
end)
