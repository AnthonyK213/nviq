---@class nviq.appl.packer.Opts
---@field confirm? boolean

---@class nviq.appl.packer.Keymap
---@field mode string
---@field lhs string
---@field rhs? string|function
---@field desc? string

---@class nviq.appl.packer.EventData
---@field active boolean
---@field kind "install"|"update"|"delete"
---@field spec nviq.appl.packer.Spec
---@field path string

---@alias nviq.appl.packer.HookCb fun(ev:nviq.appl.packer.EventData)
---@alias nviq.appl.packer.Hook {pre:nviq.appl.packer.HookCb?,post:nviq.appl.packer.HookCb?}

---@class nviq.appl.packer.Data
---@field init? fun(spec: nviq.appl.packer.Spec)
---@field conf? fun(spec: nviq.appl.packer.Spec)
---@field deps? string[]
---@field hook? nviq.appl.packer.Hook
---@field lazy? boolean
---@field cmd? string[]
---@field event? string|string[]
---@field keymap? nviq.appl.packer.Keymap[]
---@field ft? string|string[]
---@field is_loaded? boolean
---@field from_dep? boolean

---@class nviq.appl.packer.Spec : vim.pack.Spec
---@field data? nviq.appl.packer.Data

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

---Stores added specs.
---@type nviq.appl.packer.Spec[]
local _pack_specs = {}

---Stores all specs, including deps.
---@type table<string, nviq.appl.packer.Spec>
local _pack_map = {}

---Sets the spec name by src.
---@param spec nviq.appl.packer.Spec
local function spec_set_name(spec)
  local name = spec.src:gsub("%.git$", "")
  name = name:match("[^/]+$") or ""
  spec.name = name
end

---Checks whether the spec requires lazy loading.
---@param spec nviq.appl.packer.Spec
local function spec_set_lazy(spec)
  local data = spec.data
  if not data then
    return
  end

  if data.lazy ~= nil then
    return
  end

  if data.cmd and type(data.cmd) == "table" and type(data.cmd[1]) == "string" then
    data.lazy = true
    return
  end

  if data.event then
    if type(data.event) == "string" then
      data.lazy = true
      return
    elseif type(data.event) == "table" and type(data.event[1]) == "string" then
      data.lazy = true
      return
    end
  end

  if data.keymap and type(data.keymap) == "table" and data.keymap[1] then
    data.lazy = true
    return
  end

  if data.ft then
    if type(data.ft) == "string" then
      data.lazy = true
      return
    elseif type(data.ft) == "table" and type(data.ft[1]) == "string" then
      data.lazy = true
      return
    end
  end
end

---
---@param spec nviq.appl.packer.Spec
---@return string
local function spec_group_name(spec)
  return "nviq.appl.packer." .. spec.name
end

---Returns a normalized spec, which "data" is set.
---@param spec string|nviq.appl.packer.Spec
---@return nviq.appl.packer.Spec?
local function spec_normalized(spec)
  local spec_norm

  if type(spec) == "string" then
    spec_norm = {
      src  = spec,
      data = {
        lazy      = true,
        is_loaded = false,
        from_dep  = true,
      }
    }
  elseif spec.data then
    spec_norm = spec
    spec_set_lazy(spec_norm)
    spec_norm.data.is_loaded = false
    spec_norm.data.from_dep  = false
  else
    spec_norm = spec
    spec_norm.data = {
      lazy      = true,
      is_loaded = false,
      from_dep  = false,
    }
  end

  spec_set_name(spec_norm)
  if #spec_norm.name == 0 then
    return nil
  end

  return spec_norm
end

---
---@param spec nviq.appl.packer.Spec
local function spec_init(spec)
  -- Delete all autocmds.
  pcall(vim.api.nvim_del_augroup_by_name, spec_group_name(spec))

  -- Delete all commands.
  if type(spec.data.cmd) == "table" then
    for _, cmd in ipairs(spec.data.cmd) do
      pcall(vim.api.nvim_del_user_command, cmd)
    end
  end

  -- Delete all keymap hooks.
  if spec.data.keymap then
    for _, keymap in ipairs(spec.data.keymap) do
      pcall(vim.keymap.del, keymap.mode, keymap.lhs)
    end
  end

  if spec.data.init then
    spec.data.init(spec)
  end
end

---
---@param spec nviq.appl.packer.Spec
local function spec_load(spec)
  if spec.name and not spec.data.is_loaded then
    vim.cmd.packadd(spec.name)
    spec.data.is_loaded = true
    -- This spec from "load" callback is deep-copied.
    _pack_map[spec.src].data.is_loaded = true
  end
end

---
---@param spec nviq.appl.packer.Spec
local function spec_conf(spec)
  if spec.data.conf then
    spec.data.conf(spec)
  end

  -- Set keymaps.
  if spec.data.keymap then
    for _, keymap in ipairs(spec.data.keymap) do
      if keymap.rhs then
        vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs)
      end
    end
  end
end

---Loads the package immediately.
---@param spec nviq.appl.packer.Spec
local function spec_load_now(spec)
  if spec.data.is_loaded then
    return
  end

  if spec.data.deps then
    for _, dep in ipairs(spec.data.deps) do
      --- Cycle?
      local dep_spec = _pack_map[dep]
      spec_load_now(dep_spec)
    end
  end

  spec_init(spec)
  spec_load(spec)
  spec_conf(spec)
end

---Loads the package later.
---@param spec nviq.appl.packer.Spec
local function spec_load_later(spec)
  if spec.data.is_loaded or not spec.data.lazy then
    return
  end

  local data = spec.data
  if not data then
    return
  end

  -- Command trigger
  if type(data.cmd) == "table" then
    for _, cmd in ipairs(data.cmd) do
      vim.api.nvim_create_user_command(cmd, function(_)
        spec_load_now(spec)
        vim.cmd(cmd)
      end, {})
    end
  end

  -- Keymap trigger
  if type(data.keymap) == "table" then
    for _, keymap in ipairs(data.keymap) do
      vim.keymap.set(keymap.mode, keymap.lhs, function()
        spec_load_now(spec)
        require("nviq.util.k").feedkeys(keymap.lhs, "m", false)
      end)
    end
  end

  local group = vim.api.nvim_create_augroup(spec_group_name(spec), {
    clear = true
  })

  -- Event trigger
  if data.event then
    vim.api.nvim_create_autocmd(data.event, {
      group = group,
      once = true,
      callback = function(ev)
        spec_load_now(spec)
        vim.api.nvim_exec_autocmds(ev.event, { modeline = false })
      end
    })
  end

  -- FileType trigger
  if data.ft then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = data.ft,
      group = group,
      once = true,
      callback = function(ev)
        spec_load_now(spec)
        -- Re-trigger "FileType" event.
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) then
            vim.cmd("filetype detect")
          end
        end)
      end
    })
  end
end

local function set_hooks()
  local group = vim.api.nvim_create_augroup("nviq.appl.packer.pack_events", {
    clear = true
  })

  vim.api.nvim_create_autocmd("PackChangedPre", {
    group = group,
    callback = function(ev)
      local event_data = ev.data --[[@as nviq.appl.packer.EventData]]
      local spec = event_data.spec
      if not spec.data then return end
      local hook = spec.data.hook
      if not hook or not hook.pre then return end
      hook.pre(event_data)
    end
  })

  vim.api.nvim_create_autocmd("PackChanged", {
    group = group,
    callback = function(ev)
      local event_data = ev.data --[[@as nviq.appl.packer.EventData]]
      local spec = event_data.spec
      if not spec.data then return end
      local hook = spec.data.hook
      if not hook or not hook.post then return end
      hook.post(event_data)
    end
  })
end

---
---@param plug_data {spec:nviq.appl.packer.Spec, path:string}
local function on_load(plug_data)
  local spec = plug_data.spec
  if spec.data.lazy then
    spec_load_later(spec)
  else
    spec_load_now(spec)
  end
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

  local spec_norm = spec_normalized(spec)
  if not spec_norm then
    return
  end

  table.insert(_pack_specs, spec_norm)
  if _pack_map[spec_norm.src] then
    -- Prefer explicit declaration for a deps spec.
    if _pack_map[spec_norm.src].data.from_dep then
      _pack_map[spec_norm.src] = spec_norm
    end
  else
    _pack_map[spec_norm.src] = spec_norm
  end

  if spec_norm.data.deps then
    for _, dep in ipairs(spec_norm.data.deps) do
      local dep_spec = _pack_map[dep]
      if not dep_spec then
        _pack_map[dep] = spec_normalized(dep)
      end
    end
  end
end

---
function M.end_()
  if _status ~= Status.Running then
    return
  end

  ---Stores all specs, including deps.
  ---@type nviq.appl.packer.Spec[]
  local specs = {}
  for _, spec in ipairs(_pack_specs) do
    local data = spec.data
    if data then
      if data.deps then
        for _, dep in ipairs(data.deps) do
          local dep_spec = _pack_map[dep]
          if not spec.data.lazy then
            dep_spec.data.lazy = false
          end
          table.insert(specs, dep_spec)
        end
      end
    end
    table.insert(specs, spec)
  end

  set_hooks()

  vim.pack.add(specs, {
    load    = on_load,
    confirm = _options.confirm
  })

  _status = Status.Done
end

---
function M.info()
  vim.print("Loaded:")
  for _, spec in pairs(_pack_map) do
    if spec.data.is_loaded then
      vim.print("\t" .. spec.name)
    end
  end

  vim.print("Not loaded:")
  for _, spec in pairs(_pack_map) do
    if not spec.data.is_loaded then
      vim.print("\t" .. spec.name)
    end
  end
end

return M
