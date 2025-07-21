local lib = require("nviq.util.lib")
local futures = require("nviq.util.futures")

local M = {}

---Returns the root directory of this repository.
function M.get_root()
end

---Returns the current branch.
function M.get_branch()
end

---To blame someone :)
function M.blame_line()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local file = vim.api.nvim_buf_get_name(0)
  local cwd = lib.buf_dir(0)
  local range = string.format("%d,%d", lnum, lnum)
  local blame = futures.Process.new("git", {
    args = { "blame", --[["--porcelain",]] "-L", range, file },
    cwd = cwd,
  })
  blame.record = true
  futures.spawn(function()
    local code = blame:await()
    if code == 0 then
      vim.notify(blame.stdout_buf[1])
    end
  end)
end

return M
