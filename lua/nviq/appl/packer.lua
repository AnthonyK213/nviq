---@class nviq.appl.packer.Opts
---@field confirm? boolean

---@class nviq.appl.packer.Keymap
---@field modes string|string[]
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
---@field event? string|string[]
---@field keymap? nviq.appl.packer.Keymap[]
---@field filetype? string|string[]

---@class nviq.appl.packer.Spec : vim.pack.Spec
---@field data? nviq.appl.packer.Data

---@class nviq.appl.packer.Info
---@field spec nviq.appl.packer.Spec
---@field loaded boolean

local M = {}

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

---@type nviq.appl.packer.Info[]
local _pack_infos = {}

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

  for _, info in ipairs(_pack_infos) do
    if info.spec.src == spec.src then
      return
    end
  end

  table.insert(_pack_infos, {
    spec   = spec,
    loaded = false,
  })
end

---
function M.end_()
  if _status ~= Status.Running then
    return
  end

  ---@type (string|nviq.appl.packer.Spec)[]
  local specs = {}
  for _, info in ipairs(_pack_infos) do
    local data = info.spec.data
    if data and data.deps then
      for _, dep in ipairs(data.deps) do
        table.insert(specs, dep)
      end
    end
    table.insert(specs, info.spec)
  end

  vim.pack.add(specs, {
    load    = false,
    confirm = _options.confirm
  })

  for _, info in ipairs(_pack_infos) do
    local data = info.spec.data
    if not data then
      vim.pack.add({ info.spec.src }, { load = true, confirm = false })
    end
  end

  _status = Status.Done
end

return M
