-- netrw

vim.g.netrw_altv = 1
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 80
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4
vim.keymap.set("n", "<leader>op", "<Cmd>20Lexplore<CR>")

-- Completion

-- Misc

vim.keymap.set("n", "<leader>fb", ":buffer<space>")
vim.keymap.set("n", "<leader>ff", ":find<space>")
