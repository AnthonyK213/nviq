local lib = require("nviq.util.lib")
local kutil = require("nviq.util.k")

-- netrw

vim.g.netrw_altv = 1
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 80
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4

vim.keymap.set("n", "<leader>op", "<Cmd>20Lexplore<CR>")

-- LSP

vim.lsp.config("clangd", {
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = {
    ".clangd",
    ".clang-tidy",
    ".clang-format",
    "compile_commands.json",
    "compile_flags.txt",
    "configure.ac", -- AutoTools
    ".git",
  },
  capabilities = {
    textDocument = {
      completion = {
        editsNearCursor = true,
      },
    },
    offsetEncoding = { "utf-8", "utf-16" },
  },
})

-- Completion

---
---@param client vim.lsp.Client
---@return string[]?
local function get_trigger_chars(client)
  local server_capabilities = client.server_capabilities
  if not server_capabilities then return end
  local completion_provider = server_capabilities.completionProvider
  if not completion_provider then return end
  return completion_provider.triggerCharacters
end

---
---@param clients vim.lsp.Client[]
---@param context string
local function after_trigger_char(clients, context)
  if context:len() == 0 then
    return false
  end
  for _, client in ipairs(clients) do
    local trigger_chars = get_trigger_chars(client)
    if trigger_chars then
      for _, char in ipairs(trigger_chars) do
        if vim.endswith(context, char) then
          return true
        end
      end
    end
  end
  return false
end

vim.o.completeopt = "fuzzy,menu,menuone,noinsert,popup"

require("nviq.appl.lsp").register_client_on_attach(function(client, bufnr)
  vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
end)

kutil.new_keymap("i", "<CR>", function(fallback)
  if vim.fn.pumvisible() ~= 0 then
    kutil.feedkeys("<C-Y>", "in", true)
  else
    fallback()
  end
end)

kutil.new_keymap("i", "<Tab>", function(fallback)
  if vim.fn.pumvisible() ~= 0 then
    kutil.feedkeys("<C-N>", "in", true)
    return
  end

  if vim.snippet.active { direction = 1 } then
    vim.snippet.jump(1)
    return
  end

  local clients = vim.lsp.get_clients { bufnr = 0 }
  local context = lib.get_half_line(-1)

  if #clients == 0 then
    if vim.regex("\\v[A-Za-z_\\u4e00-\\u9fa5]$"):match_str(context.b) then
      kutil.feedkeys("<C-N>", "in", true)
      return
    end
  else
    if vim.regex("\\v\\h$"):match_str(context.b) or
        after_trigger_char(clients, context.b) then
      vim.lsp.completion.get()
      return
    end
  end

  fallback()
end)

kutil.new_keymap("i", "<S-Tab>", function(fallback)
  if vim.fn.pumvisible() ~= 0 then
    kutil.feedkeys("<C-P>", "in", true)
  elseif vim.snippet.active { direction = -1 } then
    vim.snippet.jump(-1)
  else
    fallback()
  end
end)

-- Git

vim.keymap.set("n", "<leader>gb", function()
  require("nviq.appl.git").blame_line()
end)

-- Misc

vim.keymap.set("n", "<leader>fb", ":buffer<space>")
vim.keymap.set("n", "<leader>ff", ":find<space>")
