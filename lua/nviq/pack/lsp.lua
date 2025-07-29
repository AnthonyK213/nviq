local mini_deps = require("mini.deps")

---------------------------------mason-lspconfig--------------------------------

mini_deps.now(function()
  mini_deps.add {
    source = "mason-org/mason-lspconfig.nvim",
    depends = {
      "neovim/nvim-lspconfig",
      "mason-org/mason.nvim",
    },
  }

  require("mason-lspconfig").setup {
    ensure_installed = vim.tbl_keys(_G.NVIQ.settings.lsp),
    automatic_enable = false,
  }
end)
