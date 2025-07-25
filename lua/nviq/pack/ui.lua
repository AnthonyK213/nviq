local mini_deps = require("mini.deps")

------------------------------------devicons------------------------------------

if _G.NVIQ.settings.tui.devicons then
  mini_deps.now(function()
    mini_deps.add { source = "nvim-tree/nvim-web-devicons" }
  end)
end

------------------------------------nightfox------------------------------------

mini_deps.now(function()
  if _G.NVIQ.settings.tui.scheme ~= "nightfox" then return end

  mini_deps.add { source = "EdenEast/nightfox.nvim" }

  require("nightfox").setup {
    options = {
      compile_path = vim.fs.joinpath(vim.fn.stdpath("data"), "nightfox"),
      compile_file_suffix = "_compiled",
      transparent = _G.NVIQ.settings.tui.transparent,
      dim_inactive = _G.NVIQ.settings.tui.auto_dim,
    },
  }

  local style_table = {
    night  = { theme = "dark", inverse = "day" },
    day    = { theme = "light", inverse = "night" },
    dawn   = { theme = "light", inverse = "dusk" },
    dusk   = { theme = "dark", inverse = "dawn" },
    nord   = { theme = "dark", inverse = "day" },
    tera   = { theme = "dark", inverse = "dawn" },
    carbon = { theme = "dark", inverse = "dawn" },
  }

  _G.NVIQ.handlers.set_theme = function(theme)
    local fox_loaded = true
    local colors_name, colors_info

    if vim.g.colors_name then
      colors_name = vim.g.colors_name:match("(.+)fox")
      colors_info = style_table[colors_name]
    else
      fox_loaded = false
    end

    if not colors_info or not fox_loaded then
      fox_loaded = false
      colors_name = _G.NVIQ.settings.tui.style
      colors_info = style_table[colors_name]
    end

    if not colors_info then return end

    if theme == colors_info.theme then
      if not fox_loaded then
        vim.cmd.colorscheme(colors_name .. "fox")
      end
    else
      vim.cmd.colorscheme(colors_info.inverse .. "fox")
    end
  end

  require("nviq.appl.theme").set_theme(_G.NVIQ.settings.tui.theme)
end)

--------------------------------indent-blankline--------------------------------

mini_deps.later(function()
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
