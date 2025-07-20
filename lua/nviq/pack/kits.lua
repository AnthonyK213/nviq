local mini_deps = require("mini.deps")
local tui_border = _G.NVIQ.settings.tui.border

--------------------------------------mason-------------------------------------

mini_deps.now(function()
  mini_deps.add { source = "mason-org/mason.nvim" }

  require("mason").setup { ui = { border = tui_border } }
end)

-------------------------------------aerial-------------------------------------

mini_deps.later(function()
  mini_deps.add { source = "stevearc/aerial.nvim" }

  require("aerial").setup {
    backends = {
      ["_"]    = { "lsp", "treesitter" },
      markdown = { "markdown" },
    },
    close_automatic_events = {},
    close_on_select = false,
    manage_folds = false,
    filter_kind = {
      ["_"] = {
        "Class",
        "Constructor",
        "Enum",
        "Function",
        "Interface",
        "Module",
        "Method",
        "Struct",
      },
      lua = {
        "Function",
        "Method",
      },
    },
    nerd_font = false,
    highlight_closest = false,
    on_attach = function(bufnr)
      local opt = { noremap = true, silent = true, buffer = bufnr }
      vim.keymap.set("n", "{", require("aerial").prev, opt)
      vim.keymap.set("n", "}", require("aerial").next, opt)
      vim.keymap.set("n", "[[", require("aerial").prev_up, opt)
      vim.keymap.set("n", "]]", require("aerial").next_up, opt)
      vim.keymap.set("n", "<leader>mv", require("aerial").toggle, opt)
      vim.keymap.set("n", "<leader>fa", "<Cmd>Telescope aerial<CR>", opt)
    end,
    float = {
      border     = tui_border,
      relative   = "win",
      min_height = { 8, 0.1 },
      max_height = 0.9,
      height     = nil,
      override   = function(conf, _) return conf end,
    },
  }
end)

--------------------------------------oil---------------------------------------

mini_deps.now(function()
  mini_deps.add { source = "stevearc/oil.nvim" }

  require("oil").setup {
    float = {
      border = tui_border,
    },
    confirmation = {
      border = tui_border,
    },
    progress = {
      border = tui_border,
    },
    ssh = {
      border = tui_border,
    },
    keymaps_help = {
      border = tui_border,
    },
  }

  vim.keymap.set("n", "<leader>op", function()
    local oil = require("oil")
    if vim.bo.filetype == "oil" then
      oil.close()
    else
      oil.open()
    end
  end, { desc = "Toggle oil buffer" })
end)

------------------------------------overseer------------------------------------

mini_deps.later(function()
  mini_deps.add { source = "stevearc/overseer.nvim" }

  require("overseer").setup { dap = false }
end)

-----------------------------------telescope------------------------------------

mini_deps.later(function()
  mini_deps.add {
    source = "nvim-telescope/telescope.nvim",
    depends = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "debugloop/telescope-undo.nvim",
    }
  }

  local border_sources = {
    bold    = { "━", "┃", "━", "┃", "┏", "┓", "┛", "┗", "┣", "┫" },
    double  = { "═", "║", "═", "║", "╔", "╗", "╝", "╚", "╠", "╣" },
    rounded = { "─", "│", "─", "│", "╭", "╮", "╯", "╰", "├", "┤" },
    single  = { "─", "│", "─", "│", "┌", "┐", "┘", "└", "├", "┤" },
  }
  local border_source = border_sources[tui_border]

  ---
  ---@param source string[]
  ---@param recipe integer[]?
  ---@return string[]?
  local function border_chars(source, recipe)
    if not source then
      return
    end
    local chars = {}
    if recipe then
      for i = 1, 8 do
        chars[i] = source[recipe[i]]
      end
    else
      for i = 1, 8 do
        chars[i] = source[i]
      end
    end
    return chars
  end

  require("telescope").setup {
    defaults = {
      mappings = {
        i = {
          ["<C-Down>"] = require("telescope.actions").cycle_history_next,
          ["<C-Up>"] = require("telescope.actions").cycle_history_prev,
        },
      },
      border = border_source ~= nil,
      borderchars = border_chars(border_source),
    },
    extensions = {
      aerial = {},
      ["ui-select"] = {
        require("telescope.themes").get_dropdown {
          border = border_source ~= nil,
          borderchars = {
            prompt = border_chars(border_source),
            results = border_chars(border_source, { 1, 2, 3, 4, 9, 10, 7, 8 }),
          }
        }
      },
      undo = {},
    }
  }

  require("telescope").load_extension("aerial")
  require("telescope").load_extension("ui-select")
  require("telescope").load_extension("undo")

  vim.keymap.set("n", "<leader>fb", function() require("telescope.builtin").buffers() end, { desc = "Pick buffers" })
  vim.keymap.set("n", "<leader>ff", function() require("telescope.builtin").find_files() end, { desc = "Find files" })
  vim.keymap.set("n", "<leader>fg", function() require("telescope.builtin").live_grep() end, { desc = "Live grep" })
  vim.keymap.set("n", "<leader>fu", function() require("telescope").extensions.undo.undo() end, { desc = "Undo tree" })
end)

-----------------------------neovim-session-manager-----------------------------

mini_deps.later(function()
  mini_deps.add {
    source = "Shatur/neovim-session-manager",
    depends = {
      "nvim-lua/plenary.nvim",
    }
  }

  require("session_manager").setup {
    sessions_dir = require("plenary.path"):new(vim.fn.stdpath("data"), "sessions"),
    path_replacer = "__",
    colon_replacer = "++",
    autoload_mode = require("session_manager.config").AutoloadMode.Disabled,
    autosave_last_session = true,
    autosave_ignore_not_normal = true,
    autosave_only_in_session = false,
  }
end)
