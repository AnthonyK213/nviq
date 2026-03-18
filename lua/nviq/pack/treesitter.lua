local mini_deps = require("mini.deps")

mini_deps.now(function()
  mini_deps.add {
    source = "nvim-treesitter/nvim-treesitter",
    checkout = "main",
  }

  local ts = require("nviq.appl.treesitter")

  local parsers = ts.get_parsers()
  if not parsers or #parsers == 0 then
    return
  end

  if vim.fn.executable("tree-sitter") == 1 then
    require("nvim-treesitter").install(parsers)
  end

  ts.setup {
    parsers = parsers,
    indentexpr = [[v:lua.require("nvim-treesitter").indentexpr()]],
  }
end)
