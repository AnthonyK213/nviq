---@class nviq.appl.packer.Opts
---@field confirm? boolean

---@class nviq.appl.packer.Keymap
---@field mode string
---@field lhs string
---@field rhs string|function
---@field desc? string

---@class nviq.appl.packer.EventData
---@field active boolean
---@field kind "install"|"update"|"delete"
---@field spec nviq.appl.packer.Spec
---@field path string

---@alias nviq.appl.packer.Hook fun(ev:nviq.appl.packer.EventData)

---@class nviq.appl.packer.Data
---@field init? fun(spec: nviq.appl.packer.Spec)
---@field conf? fun(spec: nviq.appl.packer.Spec)
---@field deps? string[]
---@field hook? {pre:nviq.appl.packer.Hook?, post:nviq.appl.packer.Hook?}
---@field cmd? string|string[]
---@field event? string|string[]
---@field keymap? nviq.appl.packer.Keymap[]
---@field ft? string|string[]

---@class nviq.appl.packer.Spec : vim.pack.Spec
---@field data? nviq.appl.packer.Data

---@class nviq.appl.packer.Info
---@field spec string|nviq.appl.packer.Spec
---@field load boolean
---@field lazy boolean

---@enum nviq.appl.packer.Status
local Status = {
  Uninit  = 0,
  Running = 1,
  Done    = 2,
}

---@type nviq.appl.upgrade.Status
local _status = 0

---@type nviq.appl.packer.Opts
local _options = {
  confirm = true,
}

---@type nviq.appl.packer.Spec[]
local _pack_specs = {}

---@type table<string, nviq.appl.packer.Info>
local _pack_infos = {}

---
---@param spec string|nviq.appl.packer.Spec
---@return boolean
local function spec_is_lazy(spec)
  if type(spec) == "string" then
    return false
  end

  local data = spec.data
  if not data then
    return false
  end

  if data.cmd then
    if type(data.cmd) == "string" then
      return true
    elseif type(data.cmd) == "table" then
      return type(data.cmd[1]) == "string"
    end
  end

  if data.event then
    if type(data.event) == "string" then
      return true
    elseif type(data.event) == "table" then
      return type(data.event[1]) == "string"
    end
  end

  if data.keymap and type(data.keymap) == "table" and data.keymap[1] then
    return true
  end

  if data.ft then
    if type(data.ft) == "string" then
      return true
    elseif type(data.ft) == "table" then
      return type(data.ft[1]) == "string"
    end
  end

  return false
end

---
---@param spec nviq.appl.packer.Spec
local function spec_init(spec)
  if not spec.data then
    return
  end

  if not spec.data.init then
    return
  end

  spec.data.init(spec)
end

---
---@param spec string|nviq.appl.packer.Spec
local function spec_load(spec)
  vim.pack.add({ spec }, { load = true, confirm = false })
end

---
---@param spec nviq.appl.packer.Spec
local function spec_conf(spec)
  if not spec.data then
    return
  end

  if not spec.data.conf then
    return
  end

  spec.data.conf(spec)
end

---
---@param spec string|nviq.appl.packer.Spec
---@return nviq.appl.packer.Info
local function info_new(spec)
  return {
    spec = spec,
    load = false,
    lazy = spec_is_lazy(spec),
  }
end

---
---@param info nviq.appl.packer.Info
local function info_load(info)
  if info.load then
    return
  end

  local spec = info.spec
  if type(spec) == "string" then
    spec_load(spec)
  else
    if spec.data and spec.data.deps then
      for _, dep in ipairs(spec.data.deps) do
        local dep_info = _pack_infos[dep]
        --- Cycle?
        info_load(dep_info)
      end
    end

    spec_init(spec)
    spec_load(spec)
    spec_conf(spec)
  end

  info.load = true
end

---
---@param info nviq.appl.packer.Info
local function info_lazy(info)
  if info.load or not info.lazy then
    return
  end

  local spec = info.spec
  if type(spec) ~= "table" then
    return
  end

  local data = spec.data
  if not data then
    return
  end

  -- Command trigger

  -- Event trigger

  -- Keymap trigger
  if type(data.keymap) == "table" then
    for _, keymap in ipairs(data.keymap) do
      if keymap.rhs then
        vim.keymap.set(keymap.mode, keymap.lhs, function()
          vim.keymap.del(keymap.mode, keymap.lhs)
          info_load(info)
          vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs)
          require("nviq.util.k").feedkeys(keymap.lhs, "m", false)
        end)
      else
        vim.keymap.set(keymap.mode, keymap.lhs, function()
          vim.keymap.del(keymap.mode, keymap.lhs)
          info_load(info)
          require("nviq.util.k").feedkeys(keymap.lhs, "m", false)
        end)
      end
    end
  end

  -- FileType trigger
end

local M = {}

---
---@param opts? nviq.appl.packer.Opts
function M.begin(opts)
  if _status ~= Status.Uninit then
    return
  end

  if opts then
    _options = opts
  end

  _status = Status.Running
end

---
---@param spec nviq.appl.packer.Spec
function M.add(spec)
  if _status ~= Status.Running then
    return
  end

  if not spec.src then
    return
  end

  if _pack_infos[spec.src] then
    return
  end

  _pack_infos[spec.src] = info_new(spec)
  table.insert(_pack_specs, spec)
end

---
function M.end_()
  if _status ~= Status.Running then
    return
  end

  ---@type (string|nviq.appl.packer.Spec)[]
  local specs = {}
  for _, spec in ipairs(_pack_specs) do
    local lazy = _pack_infos[spec.src].lazy
    local data = spec.data
    if data and data.deps then
      for _, dep in ipairs(data.deps) do
        local info = _pack_infos[dep]
        if info then
          if not lazy then
            info.lazy = false
          end
        else
          info = info_new(dep)
          info.lazy = lazy
          _pack_infos[dep] = info
          table.insert(specs, dep)
        end
      end
    end
    table.insert(specs, spec)
  end

  vim.pack.add(specs, {
    load    = false,
    confirm = _options.confirm
  })

  for _, spec in ipairs(_pack_specs) do
    local info = _pack_infos[spec.src]
    if not info.lazy then
      info_load(info)
    end
  end

  for _, spec in ipairs(_pack_specs) do
    local info = _pack_infos[spec.src]
    if info.lazy then
      info_lazy(info)
    end
  end

  _status = Status.Done
end

return M
