local mini_deps = require("mini.deps")

--------------------------------------dial--------------------------------------

mini_deps.add { source = "monaqa/dial.nvim" }

vim.keymap.set("n", "<C-A>", function() require("dial.map").manipulate("increment", "normal") end)
vim.keymap.set("n", "<C-X>", function() require("dial.map").manipulate("decrement", "normal") end)
vim.keymap.set("n", "g<C-A>", function() require("dial.map").manipulate("increment", "gnormal") end)
vim.keymap.set("n", "g<C-X>", function() require("dial.map").manipulate("decrement", "gnormal") end)
vim.keymap.set("v", "<C-A>", function() require("dial.map").manipulate("increment", "visual") end)
vim.keymap.set("v", "<C-X>", function() require("dial.map").manipulate("decrement", "visual") end)
vim.keymap.set("v", "g<C-A>", function() require("dial.map").manipulate("increment", "gvisual") end)
vim.keymap.set("v", "g<C-X>", function() require("dial.map").manipulate("decrement", "gvisual") end)

--------------------------------------peek--------------------------------------

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

if vim.fn.executable("deno") == 1 then
  mini_deps.add {
    source = "toppair/peek.nvim",
    hooks = {
      post_install  = peek_build,
      post_checkout = peek_build,
    }
  }

  require("peek").setup {
    app = "browser",
    filetype = { "markdown", "vimwiki.markdown" }
  }

  vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
  vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
  vim.api.nvim_create_user_command("PeekToggle", function()
    local peek = require("peek")
    if peek.is_open() then
      peek.close()
    else
      peek.open()
    end
  end, {})
else
  print("deno was not found")
end

-----------------------------------presenting-----------------------------------

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

---------------------------------vim-table-mode---------------------------------

vim.g.table_mode_corner = "+"

mini_deps.add { source = "dhruvasagar/vim-table-mode" }

vim.keymap.set("n", "<leader>ta", "<Cmd>TableAddFormula<CR>")
vim.keymap.set("n", "<leader>tc", "<Cmd>TableEvalFormulaLine<CR>")
vim.keymap.set("n", "<leader>tf", "<Cmd>TableModeRealign<CR>")
vim.keymap.set("n", "<leader>tm", "<Cmd>TableModeToggle<CR>")

-------------------------------------vimtex-------------------------------------

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

-------------------------------------vimwiki------------------------------------

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

mini_deps.add {
  source = "vimwiki/vimwiki",
  checkout = "dev",
}
