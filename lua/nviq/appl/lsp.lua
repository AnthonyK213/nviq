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
---@param spec nviq.core.settings.LspSpec Server configuration from `nvimrc`.
local function setup_server(name, spec)
  if type(spec) ~= "table" then return end

  ---@type vim.lsp.Config
  local cfg = {}

  if vim.lsp.config[name] then
    local on_attach = vim.lsp.config[name].on_attach
    if type(on_attach) == "function" then
      cfg.on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        custom_attach(client, bufnr)
      end
    end
  end

  cfg.on_attach = cfg.on_attach or custom_attach

  -- Set custom LSP configurations.
  if type(spec.settings) == "table" then
    cfg.settings = spec.settings
  end

  -- Configure the server.
  vim.lsp.config(name, cfg)

  -- Enable the server.
  if spec.enable then
    vim.lsp.enable(name)
  end
end

local M = {}

---Setup all LSP servers.
function M.setup()
  if type(_G.NVIQ.settings.lsp) ~= "table" then return end
  for name, conf in pairs(_G.NVIQ.settings.lsp) do
    setup_server(name, conf)
  end
end

---
---@param cb nviq.appl.lsp.OnAttach
function M.register_client_on_attach(cb)
  table.insert(_client_on_attach_queue, cb)
end

---
---@return string[]
function M.servers_to_install()
  if type(_G.NVIQ.settings.lsp) ~= "table" then
    return {}
  end

  return vim.iter(_G.NVIQ.settings.lsp)
      :filter(function(_, spec)
        return type(spec) == "table" and
            spec.enable == true and
            spec.install == true
      end)
      :map(function(name, _)
        return name
      end)
      :totable()
end

return M
