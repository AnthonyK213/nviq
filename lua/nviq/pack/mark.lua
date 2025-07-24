local mini_deps = require("mini.deps")

--------------------------------------dial--------------------------------------

mini_deps.later(function()
  mini_deps.add { source = "monaqa/dial.nvim" }

  vim.keymap.set("n", "<C-A>", function() require("dial.map").manipulate("increment", "normal") end)
  vim.keymap.set("n", "<C-X>", function() require("dial.map").manipulate("decrement", "normal") end)
  vim.keymap.set("n", "g<C-A>", function() require("dial.map").manipulate("increment", "gnormal") end)
  vim.keymap.set("n", "g<C-X>", function() require("dial.map").manipulate("decrement", "gnormal") end)
  vim.keymap.set("v", "<C-A>", function() require("dial.map").manipulate("increment", "visual") end)
  vim.keymap.set("v", "<C-X>", function() require("dial.map").manipulate("decrement", "visual") end)
  vim.keymap.set("v", "g<C-A>", function() require("dial.map").manipulate("increment", "gvisual") end)
  vim.keymap.set("v", "g<C-X>", function() require("dial.map").manipulate("decrement", "gvisual") end)
end)

--------------------------------------peek--------------------------------------

if vim.fn.executable("deno") == 1 then
  mini_deps.later(function()
    local function peek_build(args)
      if vim.fn.executable("deno") == 0 then
        print("deno was not found")
        return
      end
      print("Building peek.nvim...")
      vim.system({ "deno", "task", "--quiet", "build:fast" }, {
        cwd = args.path,
        text = true,
      }, function(obj)
        if obj.code == 0 then
          print("peek.nvim was built successfully")
        else
          print(obj.stderr)
        end
      end)
    end

    mini_deps.add {
      source = "toppair/peek.nvim",
      hooks = {
        post_install  = peek_build,
        post_checkout = peek_build,
      }
    }

    local peek = require("peek")

    peek.setup {
      app = "browser",
      filetype = { "markdown", "vimwiki.markdown" }
    }

    vim.api.nvim_create_user_command("PeekOpen", peek.open, {})
    vim.api.nvim_create_user_command("PeekClose", peek.close, {})
  end)

  -- WORKAROUND: When openning a mardown file with neovim directly, this autocmd
  -- won't be triggered if it was in the `later` block.
  local au_peek = vim.api.nvim_create_augroup("nviq.pack.mark.peek", { clear = true })
  vim.api.nvim_create_autocmd("Filetype", {
    pattern = { "markdown", "vimwiki.markdown" },
    callback = function(event)
      vim.b[event.buf].nviq_handler_preview_toggle = function()
        local has_peek, peek = pcall(require, "peek")
        if not has_peek then return end
        if peek.is_open() then
          peek.close()
        else
          peek.open()
        end
      end
    end,
    group = au_peek
  })
else
  vim.api.nvim_create_user_command("PeekOpen", [[echo "deno was not found"]], {})
  vim.api.nvim_create_user_command("PeekClose", [[echo "deno was not found"]], {})
end

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

  local augroup = vim.api.nvim_create_augroup("nviq.pack.mark.vimtex", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "tex",
    command = [[nn <leader>mv <Cmd>VimtexTocToggle<CR>]],
    group = augroup,
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
