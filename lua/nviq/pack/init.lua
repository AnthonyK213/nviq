-- No plugins when offline.
if _G.NVIQ.settings.general.offline then return end

local path_package = vim.fs.joinpath(vim.fn.stdpath("data"), "site")
local mini_path = vim.fs.joinpath(path_package, "pack/deps/start/mini.deps")
if vim.fn.executable("git") == 0 then
  vim.notify("Executable git was not found.", vim.log.levels.WARN)
  return
end
if not vim.loop.fs_stat(mini_path) then
  vim.cmd [[echo "Installing mini.deps" | redraw]]
  vim.fn.system { "git", "clone", "--filter=blob:none", "https://github.com/nvim-mini/mini.deps", mini_path }
  vim.cmd [[packadd mini.deps | helptags ALL]]
  vim.cmd [[echo "Installed mini.deps" | redraw]]
end

local mini_deps = require("mini.deps")
mini_deps.setup { path = { package = path_package } }

require("nviq.pack.ui")
require("nviq.pack.treesitter")
require("nviq.pack.kits")
require("nviq.pack.lsp")
require("nviq.pack.comp")
require("nviq.pack.git")
require("nviq.pack.dap")
require("nviq.pack.dev")
require("nviq.pack.mark")
