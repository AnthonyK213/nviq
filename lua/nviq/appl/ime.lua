local ffi = require("ffi")
local lib = require("nviq.util.lib")
local rsmod = require("nviq.appl.rsmod")

---FFI module.
---@type ffi.namespace*
local _nviq_ime = nil

local function init()
  if _nviq_ime then
    return true
  end

  local dylib_path = rsmod.get_dylib_path("nviq-ime")
  if not dylib_path then
    lib.warn("Dynamic library was not found")
    return false
  end

  ffi.cdef [[
typedef uint32_t Layout;

Layout nviq_ime_get();
void nviq_ime_set(Layout layout);
]]

  _nviq_ime = ffi.load(dylib_path)

  return true
end

---@enum nviq.appl.ime.Layout
local Layout = {
  None                = 0x0000,
  US                  = 0x0409,
  Chinese_Simplified  = 0x0804,
  Chinese_Traditional = 0x0404,
  Japanese            = 0x0411,
  Korean              = 0x0412,
}

local M = {}

M.Layout = Layout

---Returns the current keyboard layout.
---@return nviq.appl.ime.Layout
function M.get()
  if init() then
    return _nviq_ime.nviq_ime_get()
  end
  return Layout.None
end

---Sets the current keyboard layout.
---@param layout nviq.appl.ime.Layout
function M.set(layout)
  if init() then
    _nviq_ime.nviq_ime_set(layout)
  end
end

return M
