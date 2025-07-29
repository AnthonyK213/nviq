---@alias nviq.appl.lsp.OnAttach fun(client:vim.lsp.Client,bufnr:integer)

---@type nviq.appl.lsp.OnAttach[]
local _client_on_attach_queue = {}

local _float_opts = {
  border = _G.NVIQ.settings.tui.border,
  max_width = 80,
}

---Callback invoked when client attaches to a buffer.
---@param client vim.lsp.Client
---@param bufnr integer
local function custom_attach(client, bufnr)
  ---@type vim.keymap.set.Opts
  local opt = { buffer = bufnr }

  vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opt)
  vim.keymap.set("n", "<leader>l0", vim.lsp.buf.document_symbol, opt)
  vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, opt)
  vim.keymap.set("n", "<leader>ld", vim.lsp.buf.declaration, opt)
  vim.keymap.set("n", "<leader>lf", vim.lsp.buf.definition, opt)
  vim.keymap.set("n", "<leader>lh", vim.lsp.buf.signature_help, opt)
  vim.keymap.set("n", "<leader>li", vim.lsp.buf.implementation, opt)
  vim.keymap.set("n", "<leader>ln", vim.lsp.buf.rename, opt)
  vim.keymap.set("n", "<leader>lr", vim.lsp.buf.references, opt)
  vim.keymap.set("n", "<leader>lt", vim.lsp.buf.type_definition, opt)
  vim.keymap.set("n", "<leader>lw", vim.lsp.buf.workspace_symbol, opt)

  vim.keymap.set("n", "K", function()
    vim.lsp.buf.hover(_float_opts)
  end, opt)

  vim.keymap.set("n", "<leader>lm", function()
    vim.lsp.buf.format { async = false }
  end, opt)

  vim.keymap.set("n", "<leader>lk", function()
    vim.diagnostic.open_float(_float_opts)
  end, opt)

  vim.keymap.set("n", "<leader>l[", function()
    vim.diagnostic.jump {
      count = -1,
      float = _float_opts
    }
  end, opt)

  vim.keymap.set("n", "<leader>l]", function()
    vim.diagnostic.jump {
      count = 1,
      float = _float_opts
    }
  end, opt)

  for _, cb in ipairs(_client_on_attach_queue) do
    cb(client, bufnr)
  end
end

---Setup an LSP server.
---@param name string Name of the language server.
---@param conf boolean|nviq.core.settings.LspSpec Server configuration from `nvimrc`.
local function setup_server(name, conf)
  local conf_tbl

  if type(conf) == "boolean" then
    conf_tbl = { load = conf }
  elseif type(conf) == "table" then
    conf_tbl = conf
  else
    return
  end

  ---@type vim.lsp.Config
  local cfg = {}

  cfg.on_attach = custom_attach

  -- Set custom LSP configurations.
  if type(conf_tbl.settings) == "table" then
    cfg.settings = conf_tbl.settings
  end

  -- Configure the server.
  vim.lsp.config(name, cfg)

  -- Enable the server.
  if conf_tbl.load then
    vim.lsp.enable(name)
  end
end

local M = {}

---Setup all LSP servers.
function M.setup()
  if not _G.NVIQ.settings.lsp then
    return
  end

  for name, conf in pairs(_G.NVIQ.settings.lsp) do
    setup_server(name, conf)
  end
end

---
---@param cb nviq.appl.lsp.OnAttach
function M.register_client_on_attach(cb)
  table.insert(_client_on_attach_queue, cb)
end

return M
