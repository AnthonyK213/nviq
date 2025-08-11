local lib = require("nviq.util.lib")
local lsp = require("nviq.appl.lsp")
local kutil = require("nviq.util.k")

-- Vim options

vim.o.mouse = "nvic"

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
      if vim.bo.omnifunc ~= "" then
        kutil.feedkeys("<C-X><C-O>", "in", true)
      else
        kutil.feedkeys("<C-X><C-I>", "in", true)
      end
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

---@async
---@param dir string
---@return string[]?
local function git_get_files(dir)
  local futures = require("nviq.util.futures")

  local ls_files = futures.Process.new("git", {
    args = { "ls-files", "--cached", "--others", "--exclude-standard" },
    cwd = dir,
  })
  ls_files:set_record(true)
  local code, _ = ls_files:await()
  if code ~= 0 then return end

  return vim.iter(ls_files:stdout_buf()):map(function(item)
    return vim.split(item, "\n", { plain = true, trimempty = true })
  end):flatten():totable()
end

vim.keymap.set("n", "<leader>ff", function()
  local futures = require("nviq.util.futures")

  futures.spawn(function()
    local pattern = futures.ui.input { prompt = "Find file: " }
    if not pattern then return end

    local cwd = vim.fn.getcwd()
    local files = git_get_files(cwd)

    if not files then
      files = {}
      for name, type_ in vim.fs.dir(cwd, { depth = 42 }) do
        if type_ == "file" then
          table.insert(files, name)
        end
      end
    end

    ---@type string[]
    local files_matched = vim.fn.matchfuzzy(files, pattern)
    if #files_matched == 0 then
      vim.notify("Nothing found")
      return
    end

    -- Avoid filling the window since there is no select-ui...
    local n_take = math.max(math.floor(vim.o.lines * 0.38) - 2, 1)
    if #files_matched > n_take then
      files_matched = vim.iter(files_matched):take(n_take):totable()
    end

    ---@type string?
    local file = futures.ui.select(files_matched, { prompt = "Pick file: " })
    if not file then return end

    lib.edit_file(vim.fs.joinpath(cwd, file))
  end)
end, { desc = "Find file" })
