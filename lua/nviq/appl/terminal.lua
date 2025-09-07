local lib = require("nviq.util.lib")
local futures = require("nviq.util.futures")

local M = {}

---@type table<integer, nviq.futures.Terminal>
local _term_table = {}

---
---@return string[]|nil
local function get_default_cmd()
  local exec
  local shell = _G.NVIQ.settings.general.shell

  if type(shell) == "table" and #shell > 0 then
    exec = shell[1]
  elseif type(shell) == "string" then
    exec = shell
  else
    lib.warn("The shell is invalid, please check out user settings.")
    return
  end

  if not lib.has_exe(exec) then
    lib.warn(exec .. " is not a valid shell.")
    return
  end

  return vim.iter({ shell }):flatten():totable()
end

---
---@return integer|nil
local function find_window()
  local win_list = vim.api.nvim_tabpage_list_wins(0)
  for _, win in ipairs(win_list) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if _term_table[bufnr] then
      return win
    end
  end
end

---
---@return integer|nil
local function new_window()
  local height = vim.fn.winheight(0)

  local ok, win = pcall(vim.api.nvim_open_win, 0, false, {
    split  = "below",
    win    = 0,
    height = math.max(1, math.floor(height * 0.382)),
  })

  if not ok then
    vim.notify(win --[[@as string]], vim.log.levels.ERROR)
    return
  end

  if win == 0 then
    lib.warn("Failed to create a new window")
    return
  end

  return win
end

---
---@return integer|nil
local function find_or_new_window()
  return find_window() or new_window()
end

---
local function clean_up()
  for bufnr, term in pairs(_term_table) do
    if not vim.api.nvim_buf_is_loaded(bufnr) or
        not term or
        term:has_exited() then
      _term_table[bufnr] = nil
    end
  end
end

---
---@param win integer
local function focus_and_start_insert(win)
  vim.api.nvim_set_current_win(win)
  vim.cmd.startinsert()
end

---
local function new_terminal()
  local cmd = get_default_cmd()
  if not cmd then return end

  local win = find_or_new_window()
  if not win then
    return
  end

  ---@type nviq.futures.Terminal
  local term
  local ok = false
  vim.api.nvim_win_call(win, function()
    term = futures.Terminal.new(cmd)
    ok = term:start()
  end)

  if ok then
    _term_table[term:bufnr()] = term
    focus_and_start_insert(win)
  end
end

---
---@param bufnr? integer
local function toggle_terminal(bufnr)
  if not bufnr then
    return
  end

  local win = find_or_new_window()
  if not win then
    return
  end

  if bufnr ~= vim.api.nvim_win_get_buf(win) then
    vim.api.nvim_win_set_buf(win, bufnr)
  end

  focus_and_start_insert(win)
end

---Creates a new terminal.
function M.new()
  clean_up()
  new_terminal()
end

---Toggles created terminals.
function M.toggle()
  clean_up()

  local n_terms = vim.tbl_count(_term_table)
  if n_terms == 0 then
    new_terminal()
  elseif n_terms == 1 then
    local bufnr = next(_term_table)
    toggle_terminal(bufnr)
  else
    futures.spawn(function()
      local bufnr = futures.ui.select(vim.tbl_keys(_term_table), {
        prompt = "Select a terminal: ",
        format_item = function(item)
          local term = _term_table[item]
          return string.format("%s:%d", term:cmd()[1], item)
        end
      })
      toggle_terminal(bufnr)
    end)
  end
end

---Closes the current terminal.
function M.close()
  local bufnr = vim.api.nvim_get_current_buf()
  local term = _term_table[bufnr]
  if not term then
    return
  end

  term:stop()

  local ok = pcall(vim.cmd --[[@as function]], {
    cmd  = "bdelete",
    args = { bufnr },
    bang = true
  })

  if ok then
    _term_table[bufnr] = nil
  end
end

---Hides the current terminal.
function M.hide()
  local bufnr = vim.api.nvim_get_current_buf()
  if not _term_table[bufnr] then
    return
  end
  vim.api.nvim_win_hide(0)
end

return M
