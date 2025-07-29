local lib = require("nviq.util.lib")

-- netrw

vim.g.netrw_altv = 1
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 80
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4
vim.keymap.set("n", "<leader>op", "<Cmd>20Lexplore<CR>")

-- Completion

vim.o.completeopt = "menu,menuone,noselect"

lib.new_keymap("i", "<CR>", function(fallback)
  if vim.fn.pumvisible() ~= 0 then
    lib.feedkeys("<C-Y>", "n", true)
  else
    fallback()
  end
end)

lib.new_keymap("i", "<Tab>", function(fallback)
  if vim.fn.pumvisible() ~= 0 or
      vim.regex("\\v[A-Za-z_\\u4e00-\\u9fa5]$"):match_str(lib.get_half_line(-1).b) then
    lib.feedkeys("<C-N>", "n", true)
  else
    fallback()
  end
end)

lib.new_keymap("i", "<S-Tab>", function(fallback)
  if vim.fn.pumvisible() ~= 0 then
    lib.feedkeys("<C-P>", "n", true)
  else
    fallback()
  end
end)

-- Git

vim.keymap.set("n", "<leader>gb", function()
  require("nviq.appl.git").blame_line()
end)

-- Misc

vim.keymap.set("n", "<leader>fb", ":buffer<space>")
vim.keymap.set("n", "<leader>ff", ":find<space>")
