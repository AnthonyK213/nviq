local lib = require("nviq.util.lib")
local putil = require("nviq.util.p")

---@class nviq.core.settings.LspSpec
---@field load boolean
---@field disable_semantic_tokens? boolean
---@field settings? table

local settings = {
  general = {
    offline = false,
    proxy   = nil,
    shell   = ({
      [putil.OS.Unknown] = "bash",
      [putil.OS.Linux]   = "bash",
      [putil.OS.Windows] = { "powershell.exe", "-nologo" },
      [putil.OS.MacOS]   = "zsh",
    })[putil.os_type()],
    upgrade = false,
  },
  path = {
    home    = vim.env.HOME,
    desktop = vim.fs.joinpath(vim.env.HOME, "Desktop"),
    vimwiki = vim.fs.joinpath(vim.env.HOME, "vimwiki"),
  },
  tui = {
    scheme            = "default",
    theme             = "auto",
    style             = "dark",
    transparent       = false,
    global_statusline = false,
    border            = "none",
    auto_dim          = false,
    devicons          = false,
  },
  ---@type table<string, boolean|nviq.core.settings.LspSpec>
  lsp = {},
  ---@type table<string, boolean>
  dap = {},
  ts = {
    ---@type string[]
    ensure_installed = {},
  },
}

-- Merge custom settings.
local exists, opt_file = lib.get_dotfile("nvimrc")
if exists and opt_file then
  local code, result = lib.json_decode(opt_file, true)
  if code == 0 then
    settings = vim.tbl_deep_extend("force", settings, result)
  else
    lib.warn("nvimrc is invalid.")
  end
end

_G.NVIQ.settings = settings
