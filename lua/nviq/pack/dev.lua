local mini_deps = require("mini.deps")

------------------------------------colorizer-----------------------------------

-- mini_deps.later(function()
--   vim.o.termguicolors = true
--
--   mini_deps.add { source = "norcalli/nvim-colorizer.lua" }
--
--   require("colorizer").setup({
--     "html",
--     css = { names = true, rgb_fn = true },
--     vue = { names = true, rgb_fn = true },
--   }, {
--     RGB      = true,
--     RRGGBB   = true,
--     names    = false,
--     RRGGBBAA = false,
--     rgb_fn   = false,
--     hsl_fn   = false,
--     css      = false,
--     css_fn   = false,
--     mode     = "background"
--   })
-- end)

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
        vim.keymap.set("n", "K", crates.show_popup, { buffer = bufnr })
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
      "mfussenegger/nvim-dap",
    }
  }

  require("cmake-tools").setup {
    cmake_regenerate_on_save = false,
    cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
    cmake_build_directory = "build",
    cmake_compile_commands_options = {
      action = "none",
      target = vim.uv.cwd()
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
      default_opts = {
        quickfix = {
          auto_close_when_success = false,
        },
      },
    },
    cmake_runner = {
      name = "terminal",
    },
  }
end)
