local mini_deps = require("mini.deps")

-----------------------------------differview-----------------------------------

mini_deps.later(function()
  mini_deps.add { source = "sindrets/diffview.nvim" }

  local actions = require("diffview.actions")

  require("diffview").setup {
    use_icons = _G.NVIQ.settings.tui.devicons,
    icons = {
      folder_closed = ">",
      folder_open   = "v",
    },
    signs = {
      fold_closed = ">",
      fold_open   = "v",
      done        = "✓",
    },
    keymaps = {
      disable_defaults = true,
      view = {
        ["<Tab>"]           = actions.select_next_entry,
        ["<S-Tab>"]         = actions.select_prev_entry,
        ["gf"]              = actions.goto_file,
        ["<C-W><C-F>"]      = actions.goto_file_split,
        ["<C-W>gf"]         = actions.goto_file_tab,
        ["<localleader>e"]  = actions.focus_files,
        ["<localleader>b"]  = actions.toggle_files,
        ["g<C-X>"]          = actions.cycle_layout,
        ["[x"]              = actions.prev_conflict,
        ["]x"]              = actions.next_conflict,
        ["<localleader>co"] = actions.conflict_choose("ours"),
        ["<localleader>ct"] = actions.conflict_choose("theirs"),
        ["<localleader>cb"] = actions.conflict_choose("base"),
        ["<localleader>ca"] = actions.conflict_choose("all"),
        ["dx"]              = actions.conflict_choose("none"),
        ["q"]               = "<Cmd>DiffviewClose<CR>",
      },
      diff1 = {},
      diff2 = {},
      diff3 = {
        { { "n", "x" }, "2do", actions.diffget("ours") },
        { { "n", "x" }, "3do", actions.diffget("theirs") },
      },
      diff4 = {
        { { "n", "x" }, "1do", actions.diffget("base") },
        { { "n", "x" }, "2do", actions.diffget("ours") },
        { { "n", "x" }, "3do", actions.diffget("theirs") },
      },
      file_panel = {
        ["j"]              = actions.next_entry,
        ["<Down>"]         = actions.next_entry,
        ["k"]              = actions.prev_entry,
        ["<Up>"]           = actions.prev_entry,
        ["<Cr>"]           = actions.select_entry,
        ["o"]              = actions.select_entry,
        ["<2-LeftMouse>"]  = actions.select_entry,
        ["-"]              = actions.toggle_stage_entry,
        ["S"]              = actions.stage_all,
        ["U"]              = actions.unstage_all,
        ["X"]              = actions.restore_entry,
        ["L"]              = actions.open_commit_log,
        ["<C-B>"]          = actions.scroll_view(-0.25),
        ["<C-F>"]          = actions.scroll_view(0.25),
        ["<Tab>"]          = actions.select_next_entry,
        ["<S-Tab>"]        = actions.select_prev_entry,
        ["gf"]             = actions.goto_file,
        ["<C-W><C-F>"]     = actions.goto_file_split,
        ["<C-W>gf"]        = actions.goto_file_tab,
        ["i"]              = actions.listing_style,
        ["f"]              = actions.toggle_flatten_dirs,
        ["R"]              = actions.refresh_files,
        ["<localleader>e"] = actions.focus_files,
        ["<localleader>b"] = actions.toggle_files,
        ["g<C-X>"]         = actions.cycle_layout,
        ["[x"]             = actions.prev_conflict,
        ["]x"]             = actions.next_conflict,
        ["q"]              = "<Cmd>DiffviewClose<CR>",
      },
      file_history_panel = {
        ["g!"]             = actions.options,
        ["<C-M-d>"]        = actions.open_in_diffview,
        ["y"]              = actions.copy_hash,
        ["L"]              = actions.open_commit_log,
        ["zR"]             = actions.open_all_folds,
        ["zM"]             = actions.close_all_folds,
        ["j"]              = actions.next_entry,
        ["<Down>"]         = actions.next_entry,
        ["k"]              = actions.prev_entry,
        ["<Up>"]           = actions.prev_entry,
        ["<Cr>"]           = actions.select_entry,
        ["o"]              = actions.select_entry,
        ["<2-LeftMouse>"]  = actions.select_entry,
        ["<C-B>"]          = actions.scroll_view(-0.25),
        ["<C-F>"]          = actions.scroll_view(0.25),
        ["<Tab>"]          = actions.select_next_entry,
        ["<S-Tab>"]        = actions.select_prev_entry,
        ["gf"]             = actions.goto_file,
        ["<C-W><C-F>"]     = actions.goto_file_split,
        ["<C-W>gf"]        = actions.goto_file_tab,
        ["<localleader>e"] = actions.focus_files,
        ["<localleader>b"] = actions.toggle_files,
        ["g<C-X>"]         = actions.cycle_layout,
        ["q"]              = "<Cmd>DiffviewClose<CR>",
      },
      option_panel = {
        ["<Tab>"] = actions.select_entry,
        ["q"]     = actions.close,
      },
    },
  }

  vim.keymap.set("n", "<leader>gh", "<Cmd>DiffviewFileHistory<CR>")
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
      local opt = { noremap = true, silent = true, buffer = bufnr }
      vim.keymap.set("n", "<leader>gj", function() require("gitsigns").nav_hunk("next") end, opt)
      vim.keymap.set("n", "<leader>gk", function() require("gitsigns").nav_hunk("prev") end, opt)
      vim.keymap.set("n", "<leader>gp", require("gitsigns").preview_hunk, opt)
      vim.keymap.set("n", "<leader>gb", require("gitsigns").blame_line, opt)
    end
  }
end)

-------------------------------------neogit-------------------------------------

mini_deps.later(function()
  mini_deps.add {
    source = "NeogitOrg/neogit",
    depends = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    }
  }

  require("neogit").setup()

  vim.keymap.set("n", "<leader>gn", "<Cmd>Neogit<CR>")
end)
