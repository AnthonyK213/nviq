local lib = require("nviq.util.lib")

---Sets a new key mapping.
---@param desc string The description.
---@param mode string|table Mode short-name.
---@param lhs string Left-hand side {lhs} of the mapping.
---@param rhs string|function Right-hand side {rhs} of the mapping.
---@param opts? vim.keymap.set.Opts Options.
local function kbd(desc, mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  if desc then
    options.desc = desc
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

kbd("Switch to normal mode in terminal", "t", "<ESC>", "<C-\\><C-N>")
kbd("Close the terminal", "t", "<M-d>", "<C-\\><C-N><Cmd>bd!<CR>")
kbd("Find and replace", "n", "<M-g>", ":%s/", { silent = false })
kbd("Find and replace", "v", "<M-g>", ":s/", { silent = false })
kbd("Stop the search highlighting", "n", "<leader>bh", "<Cmd>noh<CR>")
kbd("Toggle spell check", "n", "<leader>cs", "<Cmd>setlocal spell! spelllang=en_us<CR>")
---@format disable-next
kbd("Write the whole buffer to the current file", { "n", "i" }, "<C-S>", function() if vim.bo.bt == "" then vim.cmd.write() end end, { silent = false })
kbd("Copy to system clipboard", "v", "<M-c>", '"+y')
kbd("Cut to system clipboard", "v", "<M-x>", '"+x')
kbd("Paste from system clipboard", { "n", "v" }, "<M-v>", '"+p')
kbd("Paste from system clipboard", "i", "<M-v>", "<C-R>=@+<CR>")
kbd("Select all lines in buffer", "n", "<M-a>", "ggVG")
kbd("Open nvimrc", "n", "<M-,>", function() require("nviq.util.misc").open_nvimrc() end)
for dir, desc in pairs { h = "left", j = "down", k = "up", l = "right" } do
  kbd("Move cursor to window: " .. desc, "n", "<M-" .. dir .. ">", function()
    lib.feedkeys("<C-W>" .. dir, "nx", false)
  end)
end
kbd("Toggle background theme", "n", "<leader>bg", function()
  if vim.is_callable(_G.NVIQ.handlers.set_theme) then
    local theme = vim.o.background == "dark" and "light" or "dark"
    _G.NVIQ.handlers.set_theme(theme)
  end
end)

-- Emacs
kbd("Move cursor to the beginning", "c", "<C-A>", "<C-B>", { silent = false })
kbd("Move cursor by one char to the left", "c", "<C-B>", "<LEFT>", { silent = false })
kbd("Move cursor by one char to the right", "c", "<C-F>", "<RIGHT>", { silent = false })
kbd("Move cursor by one WORD to the left", "c", "<M-b>", "<C-LEFT>", { silent = false })
kbd("Move cursor by one WORD to the right", "c", "<M-f>", "<C-RIGHT>", { silent = false })
kbd("Delete the word before the cursor", "c", "<M-BS>", "<C-W>", { silent = false })
kbd("Switch to command-line mode", "n", "<M-x>", ":", { silent = false })
kbd("Switch to command-line mode", "i", "<M-x>", "<C-\\><C-O>:", { silent = false })
kbd("Move cursor by one word to the left", "i", "<M-b>", "<C-\\><C-O>b")
kbd("Move cursor by one word to the right", "i", "<M-f>", "<C-\\><C-O>e<Right>")
kbd("Move cursor by one word to the left", "n", "<M-b>", "b")
kbd("Move cursor by one word to the right", "n", "<M-f>", "e")
kbd("Move cursor to the first character of the screen line", "i", "<C-A>", "<C-\\><C-O>g0")
kbd("Move cursor to the last character of the screen line", "i", "<C-E>", "<C-\\><C-O>g$")
kbd("Kill text until the end of the line", "i", "<C-K>", "<C-\\><C-O>D")
---@format disable-next
kbd("Move cursor to the left", "i", "<C-B>", [[col(".") == 1 ? "<C-\><C-O>-<C-\><C-O>$" : "]] .. lib.dir_key("l") .. '"', { expr = true, replace_keycodes = false })
---@format disable-next
kbd("Move cursor to the right", "i", "<C-F>", [[col(".") >= col("$") ? "<C-\><C-O>+<C-\><C-O>0" : "]] .. lib.dir_key("r") .. '"', { expr = true, replace_keycodes = false })
kbd("Kill text until the end of the word", "i", "<M-d>", "<C-\\><C-O>dw")
kbd("Move line up", "n", "<M-p>", [[<Cmd>exe "move" max([line(".") - 2, 0])<CR>]])
kbd("Move line down", "n", "<M-n>", [[<Cmd>exe "move" min([line(".") + 1, line("$")])<CR>]])
kbd("Move block up", "v", "<M-p>", [[:<C-U>exe "'<,'>move" max([line("'<") - 2, 0])<CR>gv]])
kbd("Move block down", "v", "<M-n>", [[:<C-U>exe "'<,'>move" min([line("'>") + 1, line("$")])<CR>gv]])
kbd("Move cursor down", { "n", "v", "i" }, "<C-N>", function() vim.cmd.normal("gj") end)
kbd("Move cursor up", { "n", "v", "i" }, "<C-P>", function() vim.cmd.normal("gk") end)

-- Buffer
kbd("Next buffer", "n", "<leader>bn", "<Cmd>bn<CR>")
kbd("Previous buffer", "n", "<leader>bp", "<Cmd>bp<CR>")
kbd("Change cwd to current buffer", "n", "<leader>bc", function()
  vim.api.nvim_set_current_dir(lib.buf_dir())
  vim.cmd.pwd()
end, { silent = false })
kbd("Delete current buffer", "n", "<leader>bd", function() require("nviq.util.misc").del_cur_buf() end)

-- Open
kbd("Open file manager", "n", "<leader>oe", function()
  local buf_dir = lib.buf_dir()
  require("nviq.util.misc").open(buf_dir)
end)
kbd("Open terminal", "n", "<leader>ot", function()
  local ok = require("nviq.util.misc").terminal()
  if ok then
    vim.api.nvim_feedkeys("i", "n", true)
  end
end)
kbd("Open URL or path under the cursor", "n", "<leader>ou", function()
  local misc = require("nviq.util.misc")
  local path = misc.match_url_or_path()
  if not path then
    lib.warn("Path not found")
    return
  end
  misc.open(path)
end)

-- Search
for key, val in pairs {
  Bing       = { "b", "https://www.bing.com/search?q=" },
  DuckDuckGo = { "d", "https://duckduckgo.com/?q=" },
  Google     = { "g", "https://www.google.com/search?q=" },
} do
  kbd("Search <cword>/selection with " .. key, { "n", "x" }, "<leader>h" .. val[1], function()
    local txt
    local mode = lib.get_mode()
    if mode == lib.Mode.Normal then
      local word = _G.NVIQ.handlers.get_word()
      txt = vim.uri_encode(word)
    elseif mode == lib.Mode.Visual then
      txt = vim.uri_encode(lib.get_gv())
    else
      return
    end
    vim.ui.open(val[2] .. txt)
  end)
end
