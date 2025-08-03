local lib = require("nviq.util.lib")

---Represents a neovim terminal.
---@class nviq.futures.Terminal : nviq.futures.Awaitable
---@field private m_cmd string[] Command with arguments.
---@field private m_opts table See `jobstart()`.
---@field private m_cb? fun(term: nviq.futures.Terminal, job_id: integer, data: integer, event: string) Callback invoked when the terminal process exits.
---@field private m_id integer `channel-id`
---@field private m_valid boolean True if the terminal process is valid.
---@field private m_exited boolean True if the terminal process has already exited.
---@field private m_cb_q fun(term: nviq.futures.Terminal, job_id: integer, data: integer, event:string)[]
---@field private m_no_cb_q boolean Mark the terminal process that its `m_cb_q` will not be executed.
---@field private m_winnr integer Window number.
---@field private m_bufnr integer Buffer number.
local Terminal = {}

---@private
Terminal.__index = Terminal

---Constructor.
---@param cmd string[] Command with arguments.
---@param option? table See `jobstart()`.
---@param on_exit? fun(term: nviq.futures.Terminal, job_id: integer, data: integer, event: string) Callback invoked when the terminal process exits (discouraged, use `continue_with` instead).
---@return nviq.futures.Terminal
function Terminal.new(cmd, option, on_exit)
  local terminal = {
    m_cmd = cmd,
    m_opts = option and vim.deepcopy(option) or {},
    m_id = -1,
    m_exited = false,
    m_valid = true,
    m_cb_q = type(on_exit) == "function" and { on_exit } or {},
    m_no_cb_q = false,
    m_winnr = -1,
    m_bufnr = -1,
  }
  terminal.m_opts.term = true
  setmetatable(terminal, Terminal)
  return terminal
end

---Clone a terminal process.
---@return nviq.futures.Terminal
function Terminal:clone()
  local terminal = Terminal.new(self.m_cmd, vim.deepcopy(self.m_opts))
  terminal.m_cb_q = vim.deepcopy(self.m_cb_q)
  return terminal
end

---Run the terminal process.
---@return boolean ok True if terminal started successfully.
---@return integer winnr Window number of the terminal, -1 on failure.
---@return integer bufnr Buffer number of the terminal, -1 on failure.
function Terminal:start()
  if not lib.has_exe(self.m_cmd[1], true) then self.m_valid = false end
  if self.m_exited or not self.m_valid then return false, -1, -1 end
  local ok, winnr, bufnr = lib.new_split(self.m_opts.split_pos or "belowright", {
    split_size = self.m_opts.split_size,
    ratio_max = self.m_opts.ratio_max,
    vertical = self.m_opts.vertical,
    hide_number = true,
  })
  if not ok then
    return false, winnr, bufnr
  end
  self.m_opts.on_exit = vim.schedule_wrap(function(job_id, data, event)
    self.m_exited = true
    if not self.m_no_cb_q then
      for _, f in ipairs(self.m_cb_q) do
        if type(f) == "function" then
          f(self, job_id, data, event)
        end
      end
    end
    if type(self.m_cb) == "function" then
      self.m_cb(self, job_id, data, event)
    end
  end)
  self.m_id = vim.fn.jobstart(self.m_cmd, self.m_opts)
  if self.m_id == 0 then
    self.m_valid = false
    print("Invalid arguments.")
    return false, winnr, bufnr
  elseif self.m_id == -1 then
    self.m_valid = false
    print("Invalid executable.")
    return false, winnr, bufnr
  end
  self.m_winnr, self.m_bufnr = winnr, bufnr
  return true, winnr, bufnr
end

---Continue with a callback function `callback`.
---The terminal process will not start automatically.
---@param callback fun(term: nviq.futures.Terminal, job_id: integer, data: integer, event: string)
---@return nviq.futures.Terminal self
function Terminal:continue_with(callback)
  table.insert(self.m_cb_q, callback)
  return self
end

---Await the terminal process.
---@return integer data
---@return string event
function Terminal:await()
  local res_data, res_event
  local co_cur = coroutine.running()
  if not co_cur then
    error("Process must await in an async block.")
  end
  self.m_cb = function(_, _, data, event)
    res_data = data
    res_event = event
    assert(coroutine.resume(co_cur))
  end
  if self:start() and not self.m_exited then
    coroutine.yield()
  end
  return res_data, res_event
end

return Terminal
