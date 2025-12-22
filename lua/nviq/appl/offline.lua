local lib = require("nviq.util.lib")
local lsp = require("nviq.appl.lsp")
local kutil = require("nviq.util.k")

-- Vim options

vim.o.mouse = "nvic"

-- netrw

vim.g.netrw_altv = 1
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 20
vim.g.netrw_liststyle = 4
vim.g.netrw_browse_split = 4
vim.g.netrw_clipboard = 0

vim.keymap.set("n", "<leader>op", "<Cmd>Lexplore<CR>")

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
  if client:supports_method(vim.lsp.protocol.Methods.textDocument_completion, bufnr) then
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

-- Find symbols

---Returns a new list filtered by symbol kind.
---@param items table[]
---@return table[]
local function get_filtered_symbols(items)
  return vim.iter(items):filter(function(item)
    return vim.list_contains(lsp.filter_symbols_kind(), item.kind)
  end):totable()
end

---Shows a filtered location list of document symbols.
---@param options vim.lsp.LocationOpts.OnList
local function show_filtered_symbols_in_loclist(options)
  options.items = get_filtered_symbols(options.items)
  vim.fn.setloclist(0, {}, " ", options)
  vim.cmd.lopen()
end

---Shows a filtered quickfix list of document symbols.
---@param options vim.lsp.LocationOpts.OnList
local function show_filtered_symbols_in_qflist(options)
  options.items = get_filtered_symbols(options.items)
  vim.fn.setqflist({}, " ", options --[[@as vim.fn.setqflist.what]])
  vim.cmd.copen()
end

---Finds symbol (fuzzy) with the input query.
---@param options vim.lsp.LocationOpts.OnList
local function find_in_filtered_symbols(options)
  local futures = require("nviq.util.futures")

  local winid = vim.api.nvim_get_current_win()

  futures.spawn(function()
    local query = futures.ui.input { prompt = "Find symbols: " }
    if not query then return end

    local new_items = get_filtered_symbols(options.items)
    new_items = vim.fn.matchfuzzy(new_items, query, { key = "text" })
    if #new_items == 0 then
      vim.notify("Nothing found")
      return
    end

    options.items = new_items
    vim.fn.setloclist(winid, {}, " ", options)
    vim.cmd.lopen()
  end)
end

---Show document symbols.
local function show_document_symbols()
  vim.lsp.buf.document_symbol { on_list = show_filtered_symbols_in_loclist }
end

---Find document symbols.
local function find_document_symbols()
  vim.lsp.buf.document_symbol { on_list = find_in_filtered_symbols }
end

---Find workspace symbols.
local function find_workspace_symbols()
  local futures = require("nviq.util.futures")

  futures.spawn(function()
    local query = futures.ui.input { prompt = "Find workspace symbols: " }
    if query then
      vim.lsp.buf.workspace_symbol(query, {
        on_list = show_filtered_symbols_in_qflist
      })
    end
  end)
end

lsp.register_client_on_attach(function(_, bufnr)
  vim.keymap.set("n", "<leader>mv", show_document_symbols, {
    buffer = bufnr,
    desc = "Show document symbols"
  })

  vim.keymap.set("n", "<leader>fa", find_document_symbols, {
    buffer = bufnr,
    desc = "Find workspace symbols"
  })

  vim.keymap.set("n", "<leader>fs", find_workspace_symbols, {
    buffer = bufnr,
    desc = "Find workspace symbols"
  })
end)

-- Pick buffers

vim.keymap.set("n", "<leader>fb", ":buffer<space>", { desc = "Pick buffers" })

-- Find files

---Finds files in dir recursively.
---@param dir string
---@return string[] files File paths (relative).
local function ls_files_default(dir)
  local files = {}
  for name, type_ in vim.fs.dir(dir, { depth = 42 }) do
    if type_ == "file" then
      table.insert(files, name)
    end
  end
  return files
end

---Finds files in dir that managed by git.
---@async
---@param dir string
---@return string[]? files File paths (relative).
local function ls_files_git(dir)
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

---Find files in dir.
---@async
---@param dir string
---@return string[]
local function ls_files(dir)
  return ls_files_git(dir) or ls_files_default(dir)
end

vim.keymap.set("n", "<leader>ff", function()
  local futures = require("nviq.util.futures")

  futures.spawn(function()
    local query = futures.ui.input { prompt = "Find files: " }
    if not query then return end

    local cwd = vim.fn.getcwd()

    local files = ls_files(cwd)
    files = vim.fn.matchfuzzy(files, query)
    if #files == 0 then
      vim.notify("Nothing found")
      return
    end

    --- Prefer vim.ui.select instead of qflist, since the qflist always jumps to
    --- the beginning of the file even though it has been openned in a buffer.

    -- Avoid filling the window since there is no select-ui...
    local n_take = math.max(math.floor(vim.o.lines * 0.38) - 2, 1)
    if #files > n_take then
      files = vim.iter(files):take(n_take):totable()
    end

    ---@type string?
    local file = futures.ui.select(files, { prompt = "Pick file: " })
    if not file then return end

    lib.edit_file(vim.fs.joinpath(cwd, file))
  end)
end, { desc = "Find files" })

-- Grep

---Grep via vimgrep.
---@param query string vim regex (very magic).
---@param dir string
---@return boolean ok
---@return any err
local function grep_default(query, dir)
  local files = ls_files(dir)
  if #files == 0 then
    return false, "Nothing found"
  end

  local query_escaped = string.format([[/\v%s/j]], vim.fn.escape(query, "/"))
  local files_escaped = vim.iter(files):map(function(file)
    return vim.fn.escape(file, [[\ ]])
  end):join(" ")

  local ok, err = pcall(vim.cmd --[[@as function]], {
    cmd  = "vimgrep",
    args = { query_escaped, files_escaped },
    bang = true,
    mods = { silent = true }
  })

  return ok, err
end

---Grep via ripgrep.
---@param query string
---@param dir string
---@return boolean ok
---@return any err
local function grep_rg(query, dir)
  local query_escaped = vim.fn.escape(query, [[\"]])
  local dir_escaped = vim.fn.escape(dir, [[\"]])
  local expr = string.format(
    [[system(["rg","--vimgrep","--hidden","-g","!.git/*","-i","-e","%s","%s"])]],
    query_escaped, dir_escaped)

  local ok, err = pcall(vim.cmd --[[@as function]], {
    cmd  = "cgetexpr",
    args = { expr },
    mods = { silent = true }
  })

  return ok, err
end

vim.keymap.set("n", "<leader>fg", function()
  local futures = require("nviq.util.futures")

  futures.spawn(function()
    local query = futures.ui.input { prompt = "Grep: " }
    if not query then return end

    local cwd = vim.fn.getcwd()

    local ok, err
    if lib.has_exe("rg") then
      ok, err = grep_rg(query, cwd)
    else
      ok, err = grep_default(query, cwd)
    end

    if ok then
      vim.cmd.copen()
    else
      vim.notify(err, vim.log.levels.ERROR)
    end
  end)
end, { desc = "Grep" })
