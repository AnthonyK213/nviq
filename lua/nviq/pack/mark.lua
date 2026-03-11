local packer = require("nviq.appl.packer")

--------------------------------------dial--------------------------------------

packer.add {
  src = "https://github.com/monaqa/dial.nvim",
  data = {
    keymap = {
      { modes = "n", lhs = "<C-A>", rhs = function()
        require("dial.map").manipulate("increment", "normal")
      end },
      { modes = "n", lhs = "<C-X>", rhs = function()
        require("dial.map").manipulate("decrement", "normal")
      end },
      { modes = "n", lhs = "g<C-A>", rhs = function()
        require("dial.map").manipulate("increment", "gnormal")
      end },
      { modes = "n", lhs = "g<C-X>", rhs = function()
        require("dial.map").manipulate("decrement", "gnormal")
      end
      },
      { modes = "v", lhs = "<C-A>", rhs = function()
        require("dial.map").manipulate("increment", "visual")
      end },
      { modes = "v", lhs = "<C-X>", rhs = function()
        require("dial.map").manipulate("decrement", "visual")
      end },
      { modes = "v", lhs = "g<C-A>", rhs = function()
        require("dial.map").manipulate("increment", "gvisual")
      end },
      { modes = "v", lhs = "g<C-X>", rhs = function()
        require("dial.map").manipulate("decrement", "gvisual")
      end },
    }
  }
}

--------------------------------markdown-preview--------------------------------

packer.add {
  src = "https://github.com/iamcco/markdown-preview.nvim",
  data = {
    init = function()
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
    end,
    conf = function()
      vim.api.nvim_create_autocmd("FileType", {
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
    end,
    hook = {
      post = function(ev)
        if ev.kind == "install" then
          vim.cmd [[packadd markdown-preview.nvim]]
          vim.cmd [[call mkdp#util#install()]]
        end
      end
    }
  },
}

-----------------------------------presenting-----------------------------------

packer.add {
  src = "https://github.com/sotte/presenting.nvim",
  data = {
    conf = function()
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
    end
  }
}

---------------------------------vim-table-mode---------------------------------

packer.add {
  src = "https://github.com/dhruvasagar/vim-table-mode",
  data = {
    keymap = {
      { modes = "n", lhs = "<leader>ta", rhs = "<Cmd>TableAddFormula<CR>" },
      { modes = "n", lhs = "<leader>tc", rhs = "<Cmd>TableEvalFormulaLine<CR>" },
      { modes = "n", lhs = "<leader>tf", rhs = "<Cmd>TableModeRealign<CR>" },
      { modes = "n", lhs = "<leader>tm", rhs = "<Cmd>TableModeToggle<CR>" },
    }
  }
}

-------------------------------------vimtex-------------------------------------

packer.add {
  src = "https://github.com/lervag/vimtex",
  data = {
    init = function()
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
    end,
    conf = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nviq.pack.mark.vimtex", { clear = true }),
        pattern = "tex",
        callback = function(event)
          vim.keymap.set("n", "<leader>mv", "<Cmd>VimtexTocToggle<CR>", { buffer = event.buf })
        end
      })
    end
  }
}

-------------------------------------vimwiki------------------------------------

packer.add {
  src = "https://github.com/vimwiki/vimwiki",
  version = "dev",
  data = {
    init = function()
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
      vim.g.vimwiki_table_auto_fmt = 0
      vim.g.vimwiki_key_mappings = {
        table_format   = 0,
        table_mappings = 0,
        lists_return   = 0,
      }
    end
  }
}
