local mini_deps = require("mini.deps")

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
  vim.g.mkdp_filetypes = { "markdown" }

  mini_deps.add {
    source = "iamcco/markdown-preview.nvim",
    hooks = {
      post_install = function()
        vim.cmd [[packadd markdown-preview.nvim]]
        vim.cmd [[call mkdp#util#install()]]
      end,
    }
  }

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("nviq.pack.mark.markdown-preview", { clear = true }),
    pattern = { "markdown" },
    callback = function(event)
      vim.b[event.buf].nviq_handler_preview_toggle = function()
        if vim.fn.exists(":MarkdownPreviewToggle") ~= 0 then
          vim.cmd.MarkdownPreviewToggle()
        end
      end
    end,
  })
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
    callback = function(event)
      vim.keymap.set("n", "<leader>mv", "<Cmd>VimtexTocToggle<CR>", { buffer = event.buf })
    end
  })
end)

------------------------------------wiki.vim------------------------------------

mini_deps.later(function()
  vim.g.wiki_root = vim.fs.normalize(_G.NVIQ.settings.path.vimwiki)
  vim.g.wiki_filetypes = { "md" }

  mini_deps.add { source = "lervag/wiki.vim" }
end)
