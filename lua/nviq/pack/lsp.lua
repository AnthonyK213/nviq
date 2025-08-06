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
    ensure_installed = require("nviq.appl.lsp").servers_to_install(),
    automatic_enable = false,
  }

  require("nviq.appl.lsp").setup()
end)
