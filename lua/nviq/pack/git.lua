local mini_deps = require("mini.deps")

------------------------------------fugitive------------------------------------

mini_deps.later(function()
  mini_deps.add { source = "tpope/vim-fugitive" }

  vim.keymap.set("n", "<leader>gn", "<Cmd>Git<CR>")

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("nviq.pack.git.fugitive", { clear = true }),
    pattern = "fugitive",
    callback = function(event)
      local opt = { buffer = event.buf }
      vim.keymap.set("n", "<leader>gp", require("nviq.appl.git").pull, opt)
    end
  })
end)

------------------------------------gitsigns------------------------------------

mini_deps.later(function()
  mini_deps.add { source = "lewis6991/gitsigns.nvim" }

  require("gitsigns").setup {
    signs = {
      add          = { text = "│" },
      change       = { text = "│" },
      delete       = { text = "_" },
      topdelete    = { text = "‾" },
      changedelete = { text = "~" },
      untracked    = { text = "┆" },
    },
    signcolumn = true,
    numhl = false,
    linehl = false,
    word_diff = false,
    watch_gitdir = {
      follow_files = true
    },
    auto_attach = true,
    attach_to_untracked = false,
    current_line_blame = false,
    current_line_blame_opts = {
      virt_text          = true,
      virt_text_pos      = "eol",
      delay              = 1000,
      ignore_whitespace  = false,
      virt_text_priority = 100,
    },
    current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
    sign_priority = 6,
    update_debounce = 100,
    status_formatter = nil,
    max_file_length = 40000,
    preview_config = {
      border = _G.NVIQ.settings.tui.border,
      style = "minimal",
      relative = "cursor",
      row = 0,
      col = 1
    },
    on_attach = function(bufnr)
      local opt = { buffer = bufnr }
      vim.keymap.set("n", "<leader>gj", function() require("gitsigns").nav_hunk("next") end, opt)
      vim.keymap.set("n", "<leader>gk", function() require("gitsigns").nav_hunk("prev") end, opt)
      vim.keymap.set("n", "<leader>gp", require("gitsigns").preview_hunk, opt)
      vim.keymap.set("n", "<leader>gb", require("gitsigns").blame_line, opt)
    end
  }
end)
