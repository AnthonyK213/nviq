local lib = require("nviq.util.lib")

vim.keymap.set("c", "<C-A>", "<C-B>", {
  desc = "Move cursor to the beginning",
})

vim.keymap.set("c", "<C-B>", "<LEFT>", {
  desc = "Move cursor by one char to the left",
})

vim.keymap.set("c", "<C-F>", "<RIGHT>", {
  desc = "Move cursor by one char to the right",
})

vim.keymap.set("c", "<M-b>", "<C-LEFT>", {
  desc = "Move cursor by one WORD to the left",
})

vim.keymap.set("c", "<M-f>", "<C-RIGHT>", {
  desc = "Move cursor by one WORD to the right",
})

vim.keymap.set("c", "<M-BS>", "<C-W>", {
  desc = "Delete the word before the cursor",
})

vim.keymap.set("i", "<M-b>", "<C-\\><C-O>b", {
  desc = "Move cursor by one word to the left"
})

vim.keymap.set("i", "<M-f>", "<C-\\><C-O>e<Right>", {
  desc = "Move cursor by one word to the right"
})

vim.keymap.set("i", "<M-d>", "<C-\\><C-O>dw", {
  desc = "Kill text until the end of the word"
})

vim.keymap.set("i", "<C-A>", "<C-\\><C-O>g0", {
  desc = "Move cursor to the first character of the screen line"
})

vim.keymap.set("i", "<C-E>", "<C-\\><C-O>g$", {
  desc = "Move cursor to the last character of the screen line"
})

vim.keymap.set("i", "<C-K>", "<C-\\><C-O>D", {
  desc = "Kill text until the end of the line"
})

vim.keymap.set("i", "<C-B>", [[col(".") == 1 ? "<C-\><C-O>-<C-\><C-O>$" : "]] .. lib.dir_key("l") .. '"', {
  expr = true,
  replace_keycodes = false,
  desc = "Move cursor to the left"
})

vim.keymap.set("i", "<C-F>", [[col(".") >= col("$") ? "<C-\><C-O>+<C-\><C-O>0" : "]] .. lib.dir_key("r") .. '"', {
  expr = true,
  replace_keycodes = false,
  desc = "Move cursor to the right"
})

vim.keymap.set("i", "<C-N>", "<C-\\><C-O>gj", {
  desc = "Move cursor down"
})

vim.keymap.set("i", "<C-P>", "<C-\\><C-O>gk", {
  desc = "Move cursor up"
})

vim.keymap.set("i", "<M-x>", "<C-\\><C-O>:", {
  desc = "Switch to command-line mode",
})

vim.keymap.set("n", "<M-x>", ":", {
  desc = "Switch to command-line mode",
})

vim.keymap.set("n", "<M-p>", [[<Cmd>exe "move" max([line(".") - 2, 0])<CR>]], {
  desc = "Move line up"
})

vim.keymap.set("n", "<M-n>", [[<Cmd>exe "move" min([line(".") + 1, line("$")])<CR>]], {
  desc = "Move line down"
})

vim.keymap.set("v", "<M-p>", [[:<C-U>exe "'<,'>move" max([line("'<") - 2, 0])<CR>gv]], {
  desc = "Move lines up"
})

vim.keymap.set("v", "<M-n>", [[:<C-U>exe "'<,'>move" min([line("'>") + 1, line("$")])<CR>gv]], {
  desc = "Move lines down"
})
