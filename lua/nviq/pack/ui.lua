local mini_deps = require("mini.deps")

------------------------------------devicons------------------------------------

if _G.NVIQ.settings.tui.devicons then
  mini_deps.now(function()
    mini_deps.add { source = "nvim-tree/nvim-web-devicons" }
  end)
end

--------------------------------indent-blankline--------------------------------

mini_deps.now(function()
  mini_deps.add { source = "lukas-reineke/indent-blankline.nvim" }

  require("ibl").setup {
    enabled = true,
    debounce = 1000,
    indent = {
      char = "▏",
    },
    viewport_buffer = {
      min = 30,
      max = 500
    },
    scope = {
      enabled            = true,
      show_start         = false,
      show_end           = false,
      injected_languages = false,
      priority           = 500,
    },
    exclude = {
      filetypes = {
        "aerial", "markdown", "presenting_markdown",
        "vimwiki", "NvimTree", "mason", "lspinfo",
        "NeogitStatus", "NeogitCommitView", "DiffviewFiles",
      },
      buftypes = {
        "help", "quickfix", "terminal", "nofile", "acwrite",
      },
    }
  }
end)

-----------------------------------vim-matchup----------------------------------

mini_deps.now(function()
  vim.g.matchup_matchparen_offscreen = { method = "popup" }
  vim.g.matchup_matchparen_deferred = 1
  vim.g.matchup_matchparen_deferred_show_delay = 100
  vim.g.matchup_matchparen_deferred_hide_delay = 700

  mini_deps.add { source = "andymass/vim-matchup" }
end)
