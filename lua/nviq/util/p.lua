-- Platform utilities.

local M = {}

---@enum nviq.enum.OS
M.OS = {
  Unknown = 0,
  Linux   = 1,
  Windows = 2,
  MacOS   = 3,
}

---Returns the extension of a dynamic library file.
---@return string?
function M.dylib_ext()
  return ({
    [M.OS.Windows] = ".dll",
    [M.OS.Linux]   = ".so",
    [M.OS.MacOS]   = ".dylib",
  })[M.os_type()]
end

---Checks whether `exe` exists.
---@param exe string Name of the executable.
---@param to_warn? boolean If true, warn when executable not found.
---@return boolean result True if `exe` is a valid executable.
function M.has_exe(exe, to_warn)
  if vim.fn.executable(exe) == 1 then
    return true
  end

  if to_warn then
    M.warn("Executable " .. exe .. " is not found.")
  end

  return false
end

---Checks whether the OS is Windows.
---@return boolean
function M.has_win()
  return jit.os == "Windows"
end

---Returns the type of current OS.
---@return nviq.enum.OS os_type Type of current OS.
function M.os_type()
  local name = vim.uv.os_uname().sysname
  if name == "Linux" then
    return M.OS.Linux
  elseif name == "Windows_NT" then
    return M.OS.Windows
  elseif name == "Darwin" then
    return M.OS.MacOS
  else
    return M.OS.Unknown
  end
end

return M
