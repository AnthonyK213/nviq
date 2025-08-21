local lib = require("nviq.util.lib")
local futil = require("nviq.util.f")
local futures = require("nviq.util.futures")

local M = {}

---Returns the root directory of this repository.
---@return string?
function M.get_root()
  return vim.fs.root(0, function(name, path)
    return name == ".git" and futil.is_dir(vim.fs.joinpath(path, name))
  end)
end

---Returns the current branch name.
---@param git_root string The root directory of the repository.
---@return string? result The current branch name.
function M.get_branch(git_root)
  local head_file = vim.fs.joinpath(git_root, "/.git/HEAD")

  local file = io.open(head_file)
  if file then
    local gitdir_line = file:read("*l")
    file:close()
    if gitdir_line then
      local branch = gitdir_line:match("^ref:%s.+/([^%s]-)$")
      if branch and #branch > 0 then
        return branch
      end
    end
  end
end

---
---@param info string
---@return table<string, string>?
local function parse_blame_info(info)
  local pattern = vim.re.compile([[
    blame <- {| head (%nl field)* (%nl) code |}
    head <- {:hash: [0-9a-f]^40 :} %s {:lnum_origin: %d+ :} %s {:lnum_final: %d+ :} %s {:lcnt: %d+ :}
    field <- {| {[%a-]+} (" ")? {[^%nl]*} |}
    code <- %t {:code: ([^%nl]*) :}
  ]], { t = "\t" })

  local captures = vim.re.match(info, pattern)
  if not captures then
    return
  end

  for _, v in ipairs(captures --[[@as table]]) do
    captures[v[1]] = v[2]
  end

  return captures --[[@as table<string, string>]]
end

---To blame someone :)
function M.blame_line()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local file = vim.api.nvim_buf_get_name(0)
  local cwd = lib.buf_dir(0)
  local range = string.format("%d,%d", lnum, lnum)
  local blame = futures.Process.new("git", {
    args = { "blame", "--line-porcelain", "-L", range, file },
    cwd = cwd,
  })
  blame:set_record(true)
  futures.spawn(function()
    local code = blame:await()
    if code ~= 0 or vim.tbl_isempty(blame:stdout_buf()) then
      vim.notify("No one to blame...")
      return
    end
    local blame_info = parse_blame_info(blame:stdout_buf()[1])
    if blame_info then
      local hash = blame_info["hash"]
      if hash:match("^0+$") then
        vim.print("Not Committed Yet")
        return
      end
      vim.print(string.format("%s %s (%s): %s",
        hash:sub(1, 8),
        blame_info["author"],
        os.date("%Y-%m-%d %H:%M", tonumber(blame_info["author-time"])),
        blame_info["summary"]
      ))
    end
  end)
end

function M.pull()
  local root = M.get_root()
  if not root then return end
  vim.print("Pulling...")
  vim.fn.jobstart({ "git", "pull" }, {
    cwd = root,
    -- To interactive with the fxxking prompt...
    pty = true,
    on_exit = function(_, code, _)
      -- TODO: Parse the stdout from pty.
      if code == 0 then
        print("Pulled")
      else
        print("Pull operation failed")
      end
    end,
    on_stdout = function(job_id, datas, _)
      for _, data in ipairs(datas --[=[@as string[]]=]) do
        if data:match("^Enter passphrase") or data:match("'s%spassword:") then
          vim.fn.inputsave()
          local prompt = data:gsub("[\n\r]", "")
          local passphrase = vim.fn.inputsecret(prompt)
          vim.fn.inputrestore()
          pcall(vim.fn.chansend, job_id, passphrase .. "\r\n")
        end
      end
    end
  })
end

return M
