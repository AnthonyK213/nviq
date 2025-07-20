local mini_deps = require("mini.deps")

------------------------------------colorizer-----------------------------------

mini_deps.later(function()
  vim.o.termguicolors = true

  mini_deps.add { source = "norcalli/nvim-colorizer.lua" }

  require("colorizer").setup({
    "html",
    css = { names = true, rgb_fn = true },
    vue = { names = true, rgb_fn = true },
  }, {
    RGB      = true,
    RRGGBB   = true,
    names    = false,
    RRGGBBAA = false,
    rgb_fn   = false,
    hsl_fn   = false,
    css      = false,
    css_fn   = false,
    mode     = "background"
  })
end)

-------------------------------------crates-------------------------------------

mini_deps.later(function()
  mini_deps.add {
    source = "saecki/crates.nvim",
    checkout = "stable",
  }

  local crates = require("crates")
  local option = {
    popup = {
      border = _G.NVIQ.settings.tui.border,
    },
    lsp = {
      enabled = true,
      on_attach = function(_, bufnr)
        vim.keymap.set("n", "K", crates.show_popup, {
          noremap = true,
          silent = true,
          buffer = bufnr
        })
      end,
      actions = true,
      completion = true,
      hover = true,
    }
  }

  if not _G.NVIQ.settings.tui.devicons then
    option.text = {
      loading    = "  Loading...",
      version    = "  %s",
      prerelease = "  %s",
      yanked     = "  %s yanked",
      nomatch    = "  Not found",
      upgrade    = "  %s",
      error      = "  Error fetching crate",
    }
    option.popup.text = {
      title                     = "# %s",
      pill_left                 = "",
      pill_right                = "",
      created_label             = "created        ",
      updated_label             = "updated        ",
      downloads_label           = "downloads      ",
      homepage_label            = "homepage       ",
      repository_label          = "repository     ",
      documentation_label       = "documentation  ",
      crates_io_label           = "crates.io      ",
      lib_rs_label              = "lib.rs         ",
      categories_label          = "categories     ",
      keywords_label            = "keywords       ",
      version                   = "%s",
      prerelease                = "%s pre-release",
      yanked                    = "%s yanked",
      enabled                   = "* s",
      transitive                = "~ s",
      normal_dependencies_title = "  Dependencies",
      build_dependencies_title  = "  Build dependencies",
      dev_dependencies_title    = "  Dev dependencies",
      optional                  = "? %s",
      loading                   = " ...",
    }
    option.completion = {
      text = {
        prerelease = " pre-release ",
        yanked     = " yanked ",
      }
    }
  end

  crates.setup(option)
end)

-----------------------------------cmake-tools----------------------------------

mini_deps.later(function()
  mini_deps.add {
    source = "Civitasv/cmake-tools.nvim",
    depends = {
      "nvim-lua/plenary.nvim",
      "stevearc/overseer.nvim",
      "akinsho/toggleterm.nvim",
      "mfussenegger/nvim-dap",
    }
  }

  require("cmake-tools").setup {
    cmake_command = "cmake",
    ctest_command = "ctest",
    cmake_use_preset = true,
    cmake_regenerate_on_save = false,
    cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
    cmake_build_options = {},
    cmake_build_directory = "build",
    cmake_compile_commands_options = {
      action = "none",
      target = vim.uv.cwd()
    },
    cmake_kits_path = nil,
    cmake_variants_message = {
      short = { show = true },
      long = { show = true, max_length = 40 },
    },
    cmake_dap_configuration = {
      name = "cpp",
      type = "codelldb",
      request = "launch",
      stopOnEntry = false,
      runInTerminal = true,
      console = "integratedTerminal",
    },
    cmake_executor = {
      name = "quickfix",
      opts = {},
      default_opts = {
        quickfix = {
          show = "always",
          position = "belowright",
          size = 10,
          encoding = "utf-8",
          auto_close_when_success = false,
        },
        toggleterm = {
          direction = "float",
          close_on_exit = false,
          auto_scroll = true,
          singleton = true,
        },
        overseer = {
          new_task_opts = {
            strategy = {
              "toggleterm",
              direction = "horizontal",
              autos_croll = true,
              quit_on_exit = "success"
            }
          },
          on_new_task = function(_)
            require("overseer").open(
              { enter = false, direction = "right" }
            )
          end,
        },
        terminal = {
          name = "Main Terminal",
          prefix_name = "[CMakeTools]: ",
          split_direction = "horizontal",
          split_size = 11,
          single_terminal_per_instance = true,
          single_terminal_per_tab = true,
          keep_terminal_static_location = true,
          start_insert = false,
          focus = false,
          do_not_add_newline = false,
        },
      },
    },
    cmake_runner = {
      name = "terminal",
      opts = {},
      default_opts = {
        quickfix = {
          show = "always",
          position = "belowright",
          size = 10,
          encoding = "utf-8",
          auto_close_when_success = false,
        },
        toggleterm = {
          direction = "float",
          close_on_exit = false,
          auto_scroll = true,
          singleton = true,
        },
        overseer = {
          new_task_opts = {
            strategy = {
              "toggleterm",
              direction = "horizontal",
              autos_croll = true,
              quit_on_exit = "success"
            }
          },
          on_new_task = function(_) end,
        },
        terminal = {
          name = "Main Terminal",
          prefix_name = "[CMakeTools]: ",
          split_direction = "horizontal",
          split_size = 11,
          single_terminal_per_instance = true,
          single_terminal_per_tab = true,
          keep_terminal_static_location = true,
          start_insert = false,
          focus = false,
          do_not_add_newline = false,
        },
      },
    },
    cmake_notifications = {
      runner = { enabled = true },
      executor = { enabled = true },
      spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      refresh_rate_ms = 100,
    },
    cmake_virtual_text_support = true,
    cmake_use_scratch_buffer = false,
  }
end)
