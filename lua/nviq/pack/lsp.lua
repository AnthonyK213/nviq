local mini_deps = require("mini.deps")

---------------------------------mason-lspconfig--------------------------------

mini_deps.now(function()
  mini_deps.add {
    source = "mason-org/mason-lspconfig.nvim",
    depends = {
      "neovim/nvim-lspconfig",
      "mason-org/mason.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
  }

  require("mason-lspconfig").setup {
    ensure_installed = vim.tbl_keys(_G.NVIQ.settings.lsp),
    automatic_enable = false,
  }
end)

-------------------------------------vim.lsp------------------------------------

local _float_opts = {
  border = _G.NVIQ.settings.tui.border,
  max_width = 80,
}

-- Attaches.
local function custom_attach(_, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  local picker = require("telescope.builtin")

  vim.keymap.set("n", "<F12>", picker.lsp_definitions, opts)
  vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
  vim.keymap.set("n", "<S-F12>", picker.lsp_references, opts)
  vim.keymap.set("n", "<F24>", picker.lsp_references, opts)
  vim.keymap.set("n", "<C-F12>", picker.lsp_implementations, opts)
  vim.keymap.set("n", "<F36>", picker.lsp_implementations, opts)

  vim.keymap.set("n", "K", function() vim.lsp.buf.hover(_float_opts) end, opts)
  vim.keymap.set("n", "<leader>l0", vim.lsp.buf.document_symbol, opts)
  vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, opts)
  vim.keymap.set("n", "<leader>ld", vim.lsp.buf.declaration, opts)
  vim.keymap.set("n", "<leader>lf", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "<leader>lh", vim.lsp.buf.signature_help, opts)
  vim.keymap.set("n", "<leader>li", vim.lsp.buf.implementation, opts)
  vim.keymap.set("n", "<leader>lm", function() vim.lsp.buf.format { async = false } end, opts)
  vim.keymap.set("n", "<leader>ln", vim.lsp.buf.rename, opts)
  vim.keymap.set("n", "<leader>lr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "<leader>lt", vim.lsp.buf.type_definition, opts)
  vim.keymap.set("n", "<leader>lw", vim.lsp.buf.workspace_symbol, opts)
  vim.keymap.set("n", "<leader>lk", function() vim.diagnostic.open_float(_float_opts) end, opts)
  vim.keymap.set("n", "<leader>l[", function() vim.diagnostic.jump { count = -1, float = _float_opts } end, opts)
  vim.keymap.set("n", "<leader>l]", function() vim.diagnostic.jump { count = 1, float = _float_opts } end, opts)
end

-- Modify or overwrite the config of a server.
local server_settings = {
  clangd = function(o, _)
    o.on_new_config = function(new_config, _)
      local status, cmake = pcall(require, "cmake-tools")
      if status then
        cmake.clangd_on_new_config(new_config)
      end
    end
  end,
}

---Setup servers.
---@param name string Name of the language server.
---@param config boolean|nviq.core.settings.LspSpec Server configuration from `nvimrc`.
local function setup_server(name, config)
  local config_table

  if type(config) == "boolean" then
    config_table = { load = config }
  elseif type(config) == "table" then
    config_table = config
  else
    return
  end

  ---@type vim.lsp.Config
  local cfg = {}

  local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if has_cmp then
    cfg.capabilities = cmp_nvim_lsp.default_capabilities()
  end
  cfg.on_attach = custom_attach

  -- Disable semantic tokens.
  if config_table.disable_semantic_tokens then
    cfg.on_attach = function(client, bufnr)
      client.server_capabilities.semanticTokensProvider = nil
      custom_attach(client, bufnr)
    end
  end

  -- Merge custom LSP configurations.
  local option_settings
  if type(config_table.settings) == "table" then
    option_settings = config_table.settings
  end
  local server_setting = server_settings[name]
  if type(server_setting) == "function" then
    server_setting(cfg, option_settings)
  else
    local s = option_settings or server_setting
    if s then
      cfg.settings = s
    end
  end

  -- Configure the server.
  vim.lsp.config(name, cfg)

  -- Enable the server.
  if config_table.load then
    vim.lsp.enable(name)
  end
end

-- Setup servers.
for name, config in pairs(_G.NVIQ.settings.lsp or {}) do
  setup_server(name, config)
end

-- Diagnostics
vim.diagnostic.config {
  virtual_text     = true,
  signs            = true,
  underline        = true,
  update_in_insert = false,
  severity_sort    = false,
  float            = _float_opts,
}
