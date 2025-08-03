local mini_deps = require("mini.deps")

---------------------------------------dap--------------------------------------

mini_deps.later(function()
  mini_deps.add {
    source = "mfussenegger/nvim-dap",
    depends = {
      "stevearc/overseer.nvim"
    }
  }

  local dap = require("dap")
  local has_win = jit.os == "Windows"
  local mason_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "mason")

  ---@class nviq.pack.dap.Adapter
  ---@field typename string
  ---@field filetype string|string[]
  ---@field option table
  ---@field configuration table
  local Adapter = {}

  Adapter.__index = Adapter

  ---Constructor.
  ---@param filetype string|string[]
  ---@param typename string
  ---@param option table
  ---@param configuration table[]
  ---@return nviq.pack.dap.Adapter
  function Adapter.new(filetype, typename, option, configuration)
    local adapter = {
      filetype = filetype,
      typename = typename,
      option = option,
      configuration = configuration,
    }
    setmetatable(adapter, Adapter)
    return adapter
  end

  ---Setup the adapter.
  function Adapter:setup()
    dap.adapters[self.typename] = self.option
    for _, config in ipairs(self.configuration) do
      config.type = self.typename
    end
    local filetype = self.filetype
    if type(filetype) == "string" then
      dap.configurations[filetype] = self.configuration
    elseif type(filetype) == "table" then
      for _, t in ipairs(filetype) do
        dap.configurations[t] = self.configuration
      end
    end
  end

  ---@type table<string, nviq.pack.dap.Adapter>
  local adapters = {}

  adapters.codelldb = Adapter.new({ "c", "cpp", "rust" }, "codelldb", {
    type = "executable",
    command = vim.fs.joinpath(mason_dir, "packages/codelldb/extension/adapter/codelldb"),
    name = "codelldb",
    detached = not has_win,
  }, {
    {
      name = "Launch",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input {
          prompt = "Path to executable: ",
          default = vim.uv.cwd() .. "/",
          completion = "file"
        }
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      args = {},
    }
  })

  local function get_netcoredbg_path()
    if has_win then
      return vim.fs.joinpath(mason_dir, "packages/netcoredbg/netcoredbg/netcoredbg")
    else
      return vim.fs.joinpath(mason_dir, "bin/netcoredbg")
    end
  end

  adapters.coreclr = Adapter.new("cs", "coreclr", {
    type = "executable",
    command = get_netcoredbg_path(),
    args = { "--interpreter=vscode" }
  }, {
    {
      name = "Launch",
      type = "coreclr",
      request = "launch",
      program = function()
        return vim.fn.input {
          prompt = "Path to dll: ",
          default = vim.uv.cwd() .. "/",
          completion = "file"
        }
      end,
    },
    {
      name = "Attach",
      type = "coreclr",
      request = "attach",
      processId = require("dap.utils").pick_process,
      args = {}
    }
  })

  local function get_python_path()
    local dir = has_win and "Scripts" or "bin"
    return vim.fs.joinpath(mason_dir, "packages/debugpy/venv", dir, "python")
  end

  adapters.python = Adapter.new("python", "python", {
    type = "executable",
    command = get_python_path(),
    args = { "-m", "debugpy.adapter" }
  }, {
    {
      type = "python",
      name = "Launch",
      request = "launch",
      program = "${file}",
      pythonPath = get_python_path,
    }
  })

  -- Setup adapters.
  if type(_G.NVIQ.settings.dap) == "table" then
    for type_, spec in pairs(_G.NVIQ.settings.dap) do
      if spec.enable then
        local adapter = adapters[type_]
        if adapter then
          adapter:setup()
        end
      end
    end
  end

  -- Enable overseer integration.
  require("overseer").enable_dap()

  -- dap-repl
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("nviq.pack.dap", { clear = true }),
    pattern = "dap-repl",
    callback = function(event)
      require("dap.ext.autocompl").attach()
      local opt = { buffer = event.buf }
      vim.keymap.set("i", "<Tab>", "<C-N>", opt)
      vim.keymap.set("i", "<S-Tab>", "<C-P>", opt)
      vim.keymap.set({ "n", "i" }, "<M-d>", "<C-\\><C-N><Cmd>bd!<CR>", opt)
    end,
  })
end)

---------------------------------mason-nvim-dap---------------------------------

mini_deps.later(function()
  mini_deps.add {
    source = "jay-babu/mason-nvim-dap.nvim",
    depends = {
      "mfussenegger/nvim-dap",
      "mason-org/mason.nvim",
    }
  }

  ---
  ---@return string[]
  local function adapters_to_install()
    if type(_G.NVIQ.settings.dap) ~= "table" then
      return {}
    end

    return vim.iter(_G.NVIQ.settings.dap)
        :filter(function(_, spec)
          -- TODO: `spec.install`
          return type(spec) == "table" and
              spec.enable == true
        end)
        :map(function(name, _)
          return name
        end)
        :totable()
  end

  require("mason-nvim-dap").setup {
    ensure_installed = adapters_to_install(),
    automatic_installation = false,
  }
end)

-------------------------------------dap-ui-------------------------------------

mini_deps.later(function()
  mini_deps.add {
    source = "rcarriga/nvim-dap-ui",
    depends = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    }
  }

  local dap = require("dap")
  local dapui = require("dapui")

  dapui.setup()

  dap.listeners.before.attach.dapui_config = function() dapui.open() end
  dap.listeners.before.launch.dapui_config = function() dapui.open() end
  dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
  dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

  vim.keymap.set("n", "<F5>", function() require("dap").continue() end)
  vim.keymap.set("n", "<F10>", function() require("dap").step_over() end)
  vim.keymap.set("n", "<F23>", function() require("dap").step_into() end)
  vim.keymap.set("n", "<S-F11>", function() require("dap").step_into() end)
  vim.keymap.set("n", "<F47>", function() require("dap").step_out() end)
  vim.keymap.set("n", "<S-C-F11>", function() require("dap").step_out() end)
  vim.keymap.set("n", "<leader>db", function() require("dap").toggle_breakpoint() end)
  vim.keymap.set("n", "<leader>dc", function() require("dap").clear_breakpoints() end)
  vim.keymap.set("n", "<leader>dl", function() require("dap").run_last() end)
  vim.keymap.set("n", "<leader>dr", function() require("dap").repl.toggle() end)
  vim.keymap.set("n", "<leader>dt", function() require("dap").terminate() end)
  vim.keymap.set("n", "<leader>dn", function() require("dapui").toggle() end)
  vim.keymap.set("n", "<leader>df", function() require("dapui").float_element() end)
  vim.keymap.set("x", "<leader>dv", function() require("dapui").eval() end)
end)
