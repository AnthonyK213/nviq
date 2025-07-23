local lib = require("nviq.util.lib")
local tutil = require("nviq.util.t")

local M = {}

-- Future

---Represents an operation which will produce values in the future.
---@class nviq.futures.Future
---@field private m_action function Function that represents the code to execute.
---@field private m_varargs table Arguments for `action`.
---@field private m_result any[] Result of the `Future`, stored in a list.
local Future = {}

---@private
Future.__index = Future

---@private
---Constructor.
---@param action function Function that represents the code to execute.
---@param ... any Arguments for `action`.
---@return nviq.futures.Future
function Future.new(action, ...)
  local future = {
    m_action = action,
    m_varargs = tutil.pack(...)
  }
  setmetatable(future, Future)
  return future
end

---Poll the future.
function Future:await()
  self.m_result = tutil.pack(self.m_action(tutil.unpack(self.m_varargs)))
  return tutil.unpack(self.m_result)
end

-- JoinHandle

---@class nviq.futures.JoinHandle
---@field private m_co thread
local JoinHandle = {}

---@private
JoinHandle.__index = JoinHandle

---@private
---Constructor.
---@param co thread
---@return nviq.futures.JoinHandle
function JoinHandle.new(co)
  local handle = {
    m_co = co,
  }
  setmetatable(handle, JoinHandle)
  return handle
end

---Wait for the associated thread to finish.
function JoinHandle:join()
  if not coroutine.running() then
    vim.wait(1e8, function()
      return coroutine.status(self.m_co) == "dead"
    end)
    self.m_co = nil
  else
    self:await()
  end
end

---@private
---Await the spawned task.
function JoinHandle:await()
  if not coroutine.running() then
    print("Not in any asynchronous block")
    return
  end
  while coroutine.status(self.m_co) ~= "dead" do
    coroutine.yield()
  end
  self.m_co = nil
end

---Check `fut_list` for `futures.join` & `futures.select`.
---@param fut_list nviq.futures.Process[]|nviq.futures.Task[]|nviq.futures.Terminal[] List of futrues.
---@return boolean
local function check_fut_list(fut_list)
  if not vim.islist(fut_list) or vim.tbl_isempty(fut_list) then
    print("fut_list should be a list-like table which is not empty.")
    return false
  end
  return true
end

---Wrap a function into an asynchronous function.
---@param func function Funtion to wrap.
---@return fun(...):nviq.futures.Future async_func Wrapped asynchronous function.
function M.async(func)
  return function(...)
    return Future.new(func, ...)
  end
end

---Await an asynchronous method or an awaitable object.
---@param obj any Object to await.
---@return any
function M.await(obj)
  return obj:await()
end

---Spawns a new asynchronous task.
---@param task function|nviq.futures.Future
function M.spawn(task)
  ---@type function
  local func
  local task_type = type(task)
  local co_cur = coroutine.running()

  if task_type == "function" then
    if co_cur then
      func = function()
        task()
        vim.uv.new_async(function()
          coroutine.resume(co_cur)
        end):send()
      end
    else
      func = task
    end
  elseif getmetatable(task) == Future then
    if co_cur then
      func = function()
        M.await(task)
        vim.uv.new_async(function()
          coroutine.resume(co_cur)
        end):send()
      end
    else
      func = function() M.await(task) end
    end
  else
    error("`task` is invalid.")
  end

  local co_new = coroutine.create(func)
  coroutine.resume(co_new)

  return JoinHandle.new(co_new)
end

---Polls multiple futures simultaneously.
---@param fut_list nviq.futures.Process[]|nviq.futures.Task[]|nviq.futures.Terminal[] List of futrues.
---@param timeout? integer Number of milliseconds to wait, default no timeout.
---@return table result List of results once complete.
function M.join(fut_list, timeout)
  local result = {}
  local count = 0
  if not check_fut_list(fut_list) then return result end
  if type(timeout) == "number" and timeout < 0 then
    print("Invalid value for timeout.")
    return result
  end
  local fut_count = #fut_list
  local co_cur = coroutine.running()
  if co_cur and coroutine.status(co_cur) ~= "dead" then
    for i, fut in ipairs(fut_list) do
      fut.m_cb = function(...)
        result[i] = tutil.pack(...)
        count = count + 1
        if count == fut_count then
          assert(coroutine.resume(co_cur))
        end
      end
      fut:start()
    end
    if count ~= fut_count then
      if timeout then
        local timer = vim.uv.new_timer()
        assert(timer, "Failed to create timer.")
        timer:start(timeout, 0, vim.schedule_wrap(function()
          timer:stop()
          timer:close()
          if coroutine.status(co_cur) == "suspended" then
            if count ~= fut_count then
              print("Time out")
            end
            assert(coroutine.resume(co_cur))
          end
        end))
      end
      coroutine.yield()
    end
  else
    for i, fut in ipairs(fut_list) do
      fut.m_cb = function(...)
        result[i] = tutil.pack(...)
        count = count + 1
      end
      fut:start()
    end
    local ok, code = vim.wait(timeout or 1e8, function()
      return count == fut_count
    end, 10)
    if not ok then
      if code == -1 then
        print("Time out.")
      else
        print("Interrupted.")
      end
    end
  end
  return tutil.unpack(result)
end

---Polls multiple futures simultaneously,
---returns once the first future is complete.
---Callbacks of each future will be ignored.
---@param fut_list nviq.futures.Process[]|nviq.futures.Task[]|nviq.futures.Terminal[] List of futrues.
function M.select(fut_list)
  local result
  if not check_fut_list(fut_list) then return result end
  local done = false
  local co_cur = coroutine.running()
  if co_cur and coroutine.status(co_cur) ~= "dead" then
    for _, fut in ipairs(fut_list) do
      fut.m_no_cb_q = true
      fut.m_cb = function(...)
        if not done then
          result = tutil.pack(...)
          done = true
          assert(coroutine.resume(co_cur))
        end
      end
      fut:start()
    end
    if not done then
      coroutine.yield()
    end
  else
    for _, fut in ipairs(fut_list) do
      fut.m_no_cb_q = true
      fut.m_cb = function(...)
        if not done then
          result = tutil.pack(...)
          done = true
        end
      end
      fut:start()
    end
    local ok, code = vim.wait(1e8, function() return done end, 10)
    if not ok then
      if code == -1 then
        print("Time out.")
      else
        print("Interrupted.")
      end
    end
  end
  return result
end

---Wrapper of lua module `vim.ui`.
M.ui = {
  ---Prompts the user for input.
  ---@param opts table Additional options. See `input()`.
  ---@return string? input Content the user typed.
  input = function(opts)
    return M.Task.new(vim.ui.input, opts):set_async(true):await()
  end,
  ---Prompts the user to pick a single item from a collection of entries.
  ---@param items table Arbitrary items.
  ---@param opts table Additional options. See `select()`.
  ---@return any? item The chosen item.
  ---@return integer? idx The 1-based index of `item` within `items`.
  select = function(items, opts)
    return M.Task.new(vim.ui.select, items, opts):set_async(true):await()
  end,
}

---@type table<string, function>
M.uv = {}

setmetatable(M.uv, {
  __index = function(_, k)
    return function(...)
      return M.Task.from_uv(k, ...):await()
    end
  end
})

M.Process = require("nviq.util.futures.proc")

M.Task = require("nviq.util.futures.task")

M.Terminal = require("nviq.util.futures.term")

M.fs = {
  ---Opens a text file, reads all the text in the file into a string,
  ---and then closes the file.
  ---@param path string The file to open for reading.
  ---@return string? content A string containing all the text in the file.
  read_all_text = function(path)
    local err, fd, stat, data
    err, fd = M.uv.fs_open(path, "r", 438)
    assert(not err, err)
    lib.try(function()
      err, stat = M.uv.fs_fstat(fd)
      assert(not err, err)
      err, data = M.uv.fs_read(fd, stat.size, 0)
      assert(not err, err)
    end).catch(function(ex)
      lib.warn(ex)
    end).finally(function()
      M.uv.fs_close(fd)
    end)
    return data
  end
}

return M
