local lib = require("nviq.util.lib")
local futil = require("nviq.util.f")
local tutil = require("nviq.util.t")
local futures = require("nviq.util.futures")

local M = {}

---Delete current buffer but preserve the window layout.
function M.del_cur_buf()
  local bufs = lib.buf_listed()
  local sp = vim.list_contains({ "acwrite", "help", "terminal", "quickfix", "nofile" }, vim.bo.bt)
  local handle = vim.api.nvim_get_current_buf()

  if (#bufs == 1 and vim.bo[handle].buflisted)
      or (#bufs == 0 and not vim.bo[handle].buflisted) then
    table.insert(bufs, vim.api.nvim_create_buf(true, true))
  end

  if #bufs >= 2 and not sp then
    local index = tutil.find_first(bufs, handle)
    vim.api.nvim_set_current_buf(bufs[index + (index == 1 and 1 or -1)])
  end

  vim.bo[handle].buflisted = false

  local ok = pcall(vim.api.nvim_buf_delete, handle, {
    force  = false,
    unload = vim.o.hidden
  })

  if not ok then
    lib.warn("Failed to delete buffer")
  end
end

---Open and edit text file in vim.
---@param file_path string File path.
---@param chdir boolean True to change cwd automatically.
function M.edit_file(file_path, chdir)
  local path = vim.fs.normalize(file_path)
  if vim.api.nvim_buf_get_name(0) == "" then
    vim.cmd.edit {
      args = { path },
      mods = {
        silent = true
      }
    }
  else
    vim.cmd.tabnew {
      args = { path },
      mods = {
        silent = true
      }
    }
  end
  if chdir then
    vim.api.nvim_set_current_dir(lib.buf_dir())
  end
end

---Matches URL or path under the cursor.
---@return string?
function M.match_url_or_path()
  local url = lib.url_match(vim.fn.expand("<cWORD>"))
  if url then
    return url
  end

  local path = vim.fn.expand("<cfile>")
  if futil.is_relative(path) then
    path = vim.fs.joinpath(lib.buf_dir(), path)
    path = vim.fs.normalize(path)
  end

  if futil.exist(path) then
    return path
  end
end

---The same as `vim.ui.open`, but uses `start` on Windows.
---@param path string Path or URL to open.
function M.open(path)
  if lib.has_win() then
    local handle
    handle = vim.uv.spawn("cmd", {
      args = { "/c", "start", '""', path }
    }, vim.schedule_wrap(function()
      handle:close()
    end))
  else
    vim.ui.open(path)
  end
end

---Opens nvimrc, if no exists, create one.
function M.open_nvimrc()
  local exists, opt_file = lib.get_dotfile("nvimrc")
  local cfg_dir = vim.fn.stdpath("config")
  if exists and opt_file then
    M.edit_file(opt_file, false)
    vim.api.nvim_set_current_dir(cfg_dir)
  elseif opt_file then
    vim.cmd.new(opt_file)
    local schema_uri = vim.uri_from_fname(vim.fs.joinpath(cfg_dir, "schema.json"))
    vim.api.nvim_buf_set_lines(0, 0, 1, true, {
      "{",
      string.format([[  "$schema": "%s"]], schema_uri),
      "}",
    })
  else
    vim.notify("No configuration directory available")
  end
end

---Opens terminal.
function M.terminal()
  local exec
  local shell = _G.NVIQ.settings.general.shell
  if type(shell) == "table" and #shell > 0 then
    exec = shell[1]
  elseif type(shell) == "string" then
    exec = shell
  else
    lib.warn("The shell is invalid, please check `nvimrc`.")
    return false
  end

  if vim.fn.executable(exec) ~= 1 then
    lib.warn(exec .. " is not a valid shell.")
    return false
  end

  return futures.Terminal.new(vim.iter({ shell }):flatten():totable()):start()
end

return M
