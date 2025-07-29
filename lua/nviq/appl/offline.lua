local lib = require("nviq.util.lib")

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

-- Completion

vim.o.completeopt = "menu,menuone,noselect"

require("nviq.appl.lsp").register_client_on_attach(function(client, bufnr)
  vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
end)

lib.new_keymap("i", "<CR>", function(fallback)
  if vim.fn.pumvisible() ~= 0 then
    lib.feedkeys("<C-Y>", "n", true)
  else
    fallback()
  end
end)

lib.new_keymap("i", "<Tab>", function(fallback)
  if vim.fn.pumvisible() ~= 0 then
    lib.feedkeys("<C-N>", "n", true)
  elseif vim.regex("\\v[A-Za-z_\\u4e00-\\u9fa5]$"):match_str(lib.get_half_line(-1).b) then
    if vim.tbl_isempty(vim.lsp.get_clients { bufnr = 0 }) then
      lib.feedkeys("<C-N>", "n", true)
    else
      vim.lsp.completion.get()
    end
  else
    fallback()
  end
end)

lib.new_keymap("i", "<S-Tab>", function(fallback)
  if vim.fn.pumvisible() ~= 0 then
    lib.feedkeys("<C-P>", "n", true)
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
