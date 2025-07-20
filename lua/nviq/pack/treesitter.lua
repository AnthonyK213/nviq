local lib = require("nviq.util.lib")
local mini_deps = require("mini.deps")

---Registers filetypes for the pasers.
---@param parser_table table<string, string|string[]>
local function register_parsers(parser_table)
  for parser, filetypes in pairs(parser_table) do
    vim.treesitter.language.register(parser, filetypes)
  end
end

---Installs the parsers.
---@param parsers string[]
---@return boolean
local function install_parsers(parsers)
  if not lib.has_exe("tree-sitter") then
    return false
  end

  if #parsers > 0 then
    require("nvim-treesitter").install(parsers)
  end

  return true
end

---Enables parsers for corresponding filetypes.
---@param parsers string[]
local function enable_parsers(parsers)
  local ft_list = {}
  for _, parser in ipairs(parsers) do
    local langs = vim.treesitter.language.get_filetypes(parser)
    for _, lang in ipairs(langs) do
      table.insert(ft_list, lang)
    end
  end

  local augroup = vim.api.nvim_create_augroup("nviq.pack.treesitter", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft_list,
    callback = function()
      vim.treesitter.start()
      vim.wo.foldexpr = [[v:lua.vim.treesitter.foldexpr()]]
      vim.bo.indentexpr = [[v:lua.require("nvim-treesitter").indentexpr()]]
    end,
    group = augroup,
  })
end

mini_deps.now(function()
  mini_deps.add {
    source = "nvim-treesitter/nvim-treesitter",
    checkout = "main",
  }

  -- Setup treesitter.
  local ts_settings = _G.NVIQ.settings.ts or {}
  ---@type string[]
  local ensure_installed = ts_settings.ensure_installed or {}

  if install_parsers(ensure_installed) then
    register_parsers {
      powershell = { "ps1" },
    }
    enable_parsers(ensure_installed)
  else
    -- TODO: Download tree-sitter cli and add it to path if not found.
    lib.warn("tree-sitter cli was not found")
  end
end)
