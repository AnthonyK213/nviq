local mini_deps = require("mini.deps")

--------------------------------------dial--------------------------------------

-- mini_deps.later(function()
--   mini_deps.add { source = "monaqa/dial.nvim" }
--
--   vim.keymap.set("n", "<C-A>", function() require("dial.map").manipulate("increment", "normal") end)
--   vim.keymap.set("n", "<C-X>", function() require("dial.map").manipulate("decrement", "normal") end)
--   vim.keymap.set("n", "g<C-A>", function() require("dial.map").manipulate("increment", "gnormal") end)
--   vim.keymap.set("n", "g<C-X>", function() require("dial.map").manipulate("decrement", "gnormal") end)
--   vim.keymap.set("v", "<C-A>", function() require("dial.map").manipulate("increment", "visual") end)
--   vim.keymap.set("v", "<C-X>", function() require("dial.map").manipulate("decrement", "visual") end)
--   vim.keymap.set("v", "g<C-A>", function() require("dial.map").manipulate("increment", "gvisual") end)
--   vim.keymap.set("v", "g<C-X>", function() require("dial.map").manipulate("decrement", "gvisual") end)
-- end)

--------------------------------markdown-preview--------------------------------

mini_deps.now(function()
  vim.g.mkdp_auto_start = 0
  vim.g.mkdp_auto_close = 1
  vim.g.mkdp_preview_options = {
    mkit = {},
    katex = {},
    uml = {},
    maid = {},
    disable_sync_scroll = 0,
    sync_scroll_type = "relative",
    hide_yaml_meta = 1,
    sequence_diagrams = {},
    flowchart_diagrams = {},
    content_editable = false,
    disable_filename = 0
  }
  vim.g.mkdp_filetypes = {
    "markdown",
    "vimwiki.markdown"
  }

  mini_deps.add {
    source = "iamcco/markdown-preview.nvim",
    hooks = {
      post_install = function()
        vim.cmd [[packadd markdown-preview.nvim]]
        vim.cmd [[call mkdp#util#install()]]
      end,
    }
  }

  vim.api.nvim_create_autocmd("Filetype", {
    group = vim.api.nvim_create_augroup("nviq.pack.mark.markdown-preview", { clear = true }),
    pattern = { "markdown", "vimwiki.markdown" },
    callback = function(event)
      vim.b[event.buf].nviq_handler_preview_toggle = function()
        if vim.fn.exists(":MarkdownPreviewToggle") ~= 0 then
          vim.cmd.MarkdownPreviewToggle()
        end
      end
    end,
  })
end)

-----------------------------------presenting-----------------------------------

mini_deps.later(function()
  mini_deps.add { source = "sotte/presenting.nvim" }

  require("presenting").setup {
    options = {
      width = 80,
    },
    keep_separator = false,
    separator = {
      markdown             = "^%-%-%-",
      ["vimwiki.markdown"] = "^%-%-%-",
    }
  }
end)

---------------------------------vim-table-mode---------------------------------

mini_deps.later(function()
  mini_deps.add { source = "dhruvasagar/vim-table-mode" }

  vim.keymap.set("n", "<leader>ta", "<Cmd>TableAddFormula<CR>")
  vim.keymap.set("n", "<leader>tc", "<Cmd>TableEvalFormulaLine<CR>")
  vim.keymap.set("n", "<leader>tf", "<Cmd>TableModeRealign<CR>")
  vim.keymap.set("n", "<leader>tm", "<Cmd>TableModeToggle<CR>")
end)

-------------------------------------vimtex-------------------------------------

mini_deps.now(function()
  vim.g.tex_flavor = "latex"
  vim.g.vimtex_toc_config = {
    split_pos = "vert rightbelow",
    split_width = 30,
    show_help = 0,
  }
  if jit.os == "Windows" then
    vim.g.vimtex_view_general_viewer = "SumatraPDF"
    vim.g.vimtex_view_general_options = "-reuse-instance -forward-search @tex @line @pdf"
  elseif jit.os == "Linux" then
    vim.g.vimtex_view_method = "zathura"
  elseif jit.os == "OSX" then
    vim.g.vimtex_view_method = "skim"
  end

  mini_deps.add { source = "lervag/vimtex" }

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("nviq.pack.mark.vimtex", { clear = true }),
    pattern = "tex",
    command = [[nn <leader>mv <Cmd>VimtexTocToggle<CR>]],
  })
end)

-------------------------------------vimwiki------------------------------------

mini_deps.later(function()
  vim.g.vimwiki_list = {
    {
      path = vim.fs.joinpath(_G.NVIQ.settings.path.vimwiki),
      path_html = vim.fs.joinpath(_G.NVIQ.settings.path.vimwiki, "html"),
      syntax = "markdown",
      ext = ".markdown"
    }
  }
  vim.g.vimwiki_commentstring = "<!--%s-->"
  vim.g.vimwiki_folding = "syntax"
  vim.g.vimwiki_filetypes = { "markdown" }
  vim.g.vimwiki_ext2syntax = { [".markdown"] = "markdown" }
  vim.g.vimwiki_key_mappings = {
    table_format   = 0,
    table_mappings = 0,
    lists_return   = 0,
  }

  mini_deps.add {
    source = "vimwiki/vimwiki",
    checkout = "dev",
  }
end)
