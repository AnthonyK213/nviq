local lib = require("nviq.util.lib")
local Job = require("nviq.util.futures.job")

---Represents a neovim terminal.
---@class nviq.futures.Terminal : nviq.futures.Job
---@field private m_win_opt table See `lib.new_split`.
---@field private m_winnr integer Window number.
---@field private m_bufnr integer Buffer number.
local Terminal = {}

---@private
Terminal.__index = Terminal

setmetatable(Terminal, { __index = Job })

---Constructor.
---@param cmd string[] Command with arguments.
---@param options? table See `jobstart-options`.
---@param win_opt? table See `lib.new_split`.
---@return nviq.futures.Terminal
function Terminal.new(cmd, options, win_opt)
  local terminal = {
    m_cmd = cmd,
    m_opts = options or {},
    m_id = -1,
    m_exited = false,
    m_cb_q = {},
    m_no_cb_q = false,
    m_win_opt = win_opt or {},
    m_winnr = -1,
    m_bufnr = -1,
  }
  terminal.m_opts.term = true
  setmetatable(terminal, Terminal)
  return terminal
end

---Run the terminal process.
---@return boolean ok True if terminal started successfully.
function Terminal:start()
  if not self:is_valid() or self:has_exited() then
    return false
  end

  local pos = self.m_win_opt.split_pos or "belowright"
  local ok, winnr, bufnr = lib.new_split(pos, self.m_win_opt)
  if not ok then return false end

  self.m_winnr, self.m_bufnr = winnr, bufnr

  return Job.start(self)
end

return Terminal
