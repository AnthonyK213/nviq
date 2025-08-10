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

---@class nviq.appl.offline.find_file.LcsInfo
---@field len integer Length of the longest match.
---@field i integer
---@field j integer

---@type nviq.appl.offline.find_file.LcsInfo
local LCS_NIL = { len = 0, i = 0, j = 0 }

---@class nviq.appl.offline.find_file.FileInfo
---@field name string The relative file path.
---@field score integer The matching score.

---@class nviq.appl.offline.find_file.LcsMemo
---@field private m_data nviq.appl.offline.find_file.LcsInfo[][]
local LcsMemo = {}

---@private
LcsMemo.__index = LcsMemo

---
---@return nviq.appl.offline.find_file.LcsMemo
function LcsMemo.new()
  local lcs_memo = { m_data = {} }
  setmetatable(lcs_memo, LcsMemo)
  return lcs_memo
end

---
---@param i integer
---@param j integer
---@return nviq.appl.offline.find_file.LcsInfo
function LcsMemo:get(i, j)
  return vim.tbl_get(self.m_data, i, j) or LCS_NIL
end

---
---@param i integer
---@param j integer
---@param info nviq.appl.offline.find_file.LcsInfo
function LcsMemo:set(i, j, info)
  if not self.m_data[i] then
    self.m_data[i] = {}
  end
  self.m_data[i][j] = info
end

---Extracts the matching position.
---@param i integer
---@param j integer
---@return integer[]
function LcsMemo:get_pos(i, j)
  local pos = {}
  local info = self:get(i, j)
  while info.len > 0 do
    pos[info.len] = info.i
    info = self:get(info.i - 1, info.j - 1)
  end
  return pos
end

---
---@param target string
---@param query string[]
---@return integer[]
local function lcs(target, query)
  local dp = LcsMemo.new()

  local n1, n2 = #target, #query
  for i = 1, n1 do
    for j = 1, n2 do
      if target:sub(i, i) == query[j] then
        dp:set(i, j, {
          len = dp:get(i - 1, j - 1).len + 1,
          i = i,
          j = j,
        })
      else
        local a = dp:get(i - 1, j)
        local b = dp:get(i, j - 1)
        dp:set(i, j, (a.len >= b.len) and a or b)
      end
    end
  end

  return dp:get_pos(n1, n2)
end

---
---@param match integer[]
---@param target string
---@return integer
local function match_score(match, target)
  local score = #match
  -- Prefers continuous matching.
  for i = 2, #match do
    if match[i] - match[i - 1] == 1 then
      score = score + 2
    end
  end
  -- Prefers to match end to end.
  local front = match[1] - 1
  local prev_char = target:sub(front, front)
  if prev_char == "" or prev_char == "/" then
    score = score + 1
  end
  local back = match[#match] + 1
  local next_char = target:sub(back, back)
  if next_char == "" then
    score = score + 1
  end
  return score
end

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

    ---@type nviq.appl.offline.find_file.FileInfo[]
    local file_infos = {}
    local query = vim.split(pattern:lower(), "")

    for _, file in ipairs(files) do
      local pos = lcs(file:lower(), query)
      if #pos > 0 then
        table.insert(file_infos, {
          name  = file,
          score = match_score(pos, file),
        })
      end
    end

    if #file_infos == 0 then
      vim.notify("Nothing found")
      return
    end

    table.sort(file_infos, function(a, b) return a.score > b.score end)

    -- Only show the first 10 matches.
    file_infos = vim.iter(file_infos):take(10):totable()

    ---@type nviq.appl.offline.find_file.FileInfo
    local info = futures.ui.select(file_infos, {
      prompt = "Pick file: ",
      format_item = function(item) return item.name end
    })
    if not info then return end

    lib.edit_file(vim.fs.joinpath(cwd, info.name))
  end)
end, { desc = "Find file" })
