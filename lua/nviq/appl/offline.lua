local lib = require("nviq.util.lib")
local lsp = require("nviq.appl.lsp")
local kutil = require("nviq.util.k")

-- netrw

vim.g.netrw_altv = 1
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 80
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4

vim.keymap.set("n", "<leader>op", "<Cmd>20Lexplore<CR>")

-- LSP
-- From [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)

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

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = {
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
    ".git",
  },
})

vim.lsp.config("rust_analyzer", {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = {
    "Cargo.toml",
    ".git",
  },
  capabilities = {
    experimental = {
      serverStatusNotification = true,
    },
  },
})

lsp.setup()

-- Treesitter

require("nviq.appl.treesitter").setup()

-- Completion

vim.o.completeopt = "fuzzy,menu,menuone,noinsert,popup"

lsp.register_client_on_attach(function(client, bufnr)
  if client:supports_method("textDocument/completion", bufnr) then
    vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
  end
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
    if context.b:match("[%w._:]$") then
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

-- Find buffer

vim.keymap.set("n", "<leader>fb", ":buffer<space>", { desc = "Find buffer" })

-- Find file

vim.keymap.set("n", "<leader>ff", function()
  local futures = require("nviq.util.futures")

  futures.spawn(function()
    local pattern = futures.ui.input { prompt = "Find file: " }
    if not pattern then return end
    pattern = pattern:lower()

    local cwd = vim.fn.getcwd()

    local items = vim.fs.find(function(name --[[@as string]], _)
      return name:lower():match(pattern)
    end, { path = cwd, type = "file", limit = 10 })

    if #items == 0 then
      vim.notify("Nothing found")
      return
    end

    local file_path = futures.ui.select(items, {
      prompt = "Pick file: ",
      format_item = function(item)
        return vim.fs.relpath(cwd, item) or item
      end
    })
    if not file_path then return end

    lib.edit_file(file_path)
  end)
end, { desc = "Find file" })
