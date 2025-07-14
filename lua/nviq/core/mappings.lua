local lib = require("nviq.util.lib")

-- Directional operation that won't break the history.
vim.g.nviq_const_dir_l = vim.api.nvim_replace_termcodes(lib.dir_key("l"), true, false, true)
vim.g.nviq_const_dir_r = vim.api.nvim_replace_termcodes(lib.dir_key("r"), true, false, true)
vim.g.nviq_const_dir_u = vim.api.nvim_replace_termcodes(lib.dir_key("u"), true, false, true)
vim.g.nviq_const_dir_d = vim.api.nvim_replace_termcodes(lib.dir_key("d"), true, false, true)

---Sets a new key mapping.
---@param desc string The description.
---@param mode string|table Mode short-name.
---@param lhs string Left-hand side {lhs} of the mapping.
---@param rhs string|function Right-hand side {rhs} of the mapping.
---@param opts? table Options.
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

---Normal mode or Visual mode?
---@return string?
local function get_mode()
  local m = vim.api.nvim_get_mode().mode
  if m == "n" then
    return m
  elseif vim.list_contains({ "v", "V", "" }, m) then
    return "v"
  else
    return nil
  end
end

---Switches mode to normal.
local function to_normal()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-N>", false, true, true), "nx", false)
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
kbd("Move cursor to the left", "i", "<C-B>", [[col(".") == 1 ? "<C-\><C-O>-<C-\><C-O>$" : g:nviq_const_dir_l]], { expr = true, replace_keycodes = false })
---@format disable-next
kbd("Move cursor to the right", "i", "<C-F>", [[col(".") >= col("$") ? "<C-\><C-O>+" : g:nviq_const_dir_r]], { expr = true, replace_keycodes = false })
kbd("Kill text until the end of the word", "i", "<M-d>", "<C-\\><C-O>dw")
kbd("Move line up", "n", "<M-p>", [[<Cmd>exe "move" max([line(".") - 2, 0])<CR>]])
kbd("Move line down", "n", "<M-n>", [[<Cmd>exe "move" min([line(".") + 1, line("$")])<CR>]])
kbd("Move block up", "v", "<M-p>", [[:<C-U>exe "'<,'>move" max([line("'<") - 2, 0])<CR>gv]])
kbd("Move block down", "v", "<M-n>", [[:<C-U>exe "'<,'>move" min([line("'>") + 1, line("$")])<CR>gv]])
kbd("Move cursor down", { "n", "v", "i" }, "<C-N>", function() vim.cmd.normal("gj") end)
kbd("Move cursor up", { "n", "v", "i" }, "<C-P>", function() vim.cmd.normal("gk") end)

-- Open
kbd("Open terminal", "n", "<leader>ot", function()
  local ok = require("nviq.util.misc").terminal()
  if ok then
    vim.api.nvim_feedkeys("i", "n", true)
  end
end)

-- Buffer
kbd("Next buffer", "n", "<leader>bn", "<Cmd>bn<CR>")
kbd("Previous buffer", "n", "<leader>bp", "<Cmd>bp<CR>")
kbd("Change cwd to current buffer", "n", "<leader>bc", function()
  vim.api.nvim_set_current_dir(lib.buf_dir())
  vim.cmd.pwd()
end, { silent = false })
kbd("Delete current buffer", "n", "<leader>bd", function() require("nviq.util.misc").del_cur_buf() end)

-- Search
for key, val in pairs {
  Bing       = { "b", "https://www.bing.com/search?q=" },
  DuckDuckGo = { "d", "https://duckduckgo.com/?q=" },
  Google     = { "g", "https://www.google.com/search?q=" },
} do
  kbd("Search <cword>/selection with " .. key, { "n", "x" }, "<leader>h" .. val[1], function()
    local txt
    local mode = get_mode()
    if mode == "n" then
      local word = _G.NVIQ.handlers.get_word()
      txt = vim.uri_encode(word)
    elseif mode == "v" then
      txt = vim.uri_encode(lib.get_gv())
    else
      return
    end
    vim.ui.open(val[2] .. txt)
  end)
end

-- Autopair
require("nviq.util.autopair").setup {
  pairs = {
    ["()"] = { left = "(", right = ")" },
    ["[]"] = { left = "[", right = "]" },
    ["{}"] = { left = "{", right = "}" },
    ["''"] = { left = "'", right = "'" },
    ['""'] = { left = '"', right = '"' },
    tex_bf = { left = "\\textbf{", right = "}" },
    tex_it = { left = "\\textit{", right = "}" },
    tex_rm = { left = "\\textrm{", right = "}" },
    md_p   = { left = "`", right = "`" },
    md_i   = { left = "*", right = "*" },
    md_b   = { left = "**", right = "**" },
    md_m   = { left = "***", right = "***" },
    md_u   = { left = "<u>", right = "</u>" },
  },
  keymaps = {
    ["("] = { action = "open", pair = "()" },
    [")"] = { action = "close", pair = "()" },
    ["["] = { action = "open", pair = "[]" },
    ["]"] = { action = "close", pair = "[]" },
    ["{"] = { action = "open", pair = "{}" },
    ["}"] = { action = "close", pair = "{}" },
    ["'"] = {
      action = "closeopen",
      pair = {
        ["_"] = "''",
        lisp = "",
        rust = "",
      }
    },
    ['"'] = { action = "closeopen", pair = '""' },
    ["<M-P>"] = {
      action = "closeopen",
      pair = {
        markdown = "md_p",
      }
    },
    ["<M-I>"] = {
      action = "closeopen",
      pair = {
        markdown = "md_i",
        tex = "tex_it",
      }
    },
    ["<M-B>"] = {
      action = "closeopen",
      pair = {
        markdown = "md_b",
        tex = "tex_bf",
      }
    },
    ["<M-N>"] = {
      action = "closeopen",
      pair = {
        markdown = "tex_rm",
        tex = "tex_rm",
      }
    },
    ["<M-M>"] = {
      action = "closeopen",
      pair = {
        markdown = "md_m"
      }
    },
    ["<M-U>"] = {
      action = "closeopen",
      pair = {
        markdown = "md_u"
      }
    },
  }
}

-- Commenting
kbd("Toggle comment", "x", "<leader>kc", function()
  return require("vim._comment").operator()
end, { expr = true })
kbd("Toggle comment line", "n", "<leader>kc", function()
  return require("vim._comment").operator() .. "_"
end, { expr = true })

-- Surrounding
kbd("Insert surrounding", { "n", "x" }, "<leader>sa", function()
  if not vim.bo.modifiable then return end
  local mode = get_mode()
  if not mode then return end
  to_normal()
  local futures = require("nviq.util.futures")
  futures.spawn(function()
    local left = futures.ui.input { prompt = "Insert surrounding: " }
    if not left then return end
    require("nviq.util.surround").insert(mode, left, _G.NVIQ.handlers.get_word)
  end)
end)
kbd("Delete surrounding", "n", "<leader>sd", function()
  if not vim.bo.modifiable then return end
  local futures = require("nviq.util.futures")
  futures.spawn(function()
    local left = futures.ui.input { prompt = "Delete surrounding: " }
    if not left then return end
    require("nviq.util.surround").delete(left)
  end)
end)
kbd("Change surrounding", "n", "<leader>sc", function()
  if not vim.bo.modifiable then return end
  local futures = require("nviq.util.futures")
  futures.spawn(function()
    local old = futures.ui.input { prompt = "Change surrounding: " }
    if not old then return end
    local new = futures.ui.input { prompt = "New surrounding: " }
    if not new then return end
    require("nviq.util.surround").change(old, new)
  end)
end)

-- Jieba
kbd("Toggle jieba-mode.", "n", "<leader>jm", function()
  local jieba = require("nviq.appl.jieba")
  if jieba.is_enabled() then
    jieba:disable()
    vim.notify("Jieba is disabled")
  else
    if jieba:enable() then
      vim.notify("Jieba is enabled")
    end
  end
end)

-- Stardict
kbd("Look up the word under the cursor", { "n", "x" }, "<leader>hh", function()
  local word
  local mode = get_mode()
  if mode == "n" then
    word = NVIQ.handlers.get_word()
  elseif mode == "v" then
    word = lib.get_gv()
  else
    return
  end
  require("nviq.appl.stardict").stardict(word)
end)

-- Theme
kbd("Toggle background theme", "n", "<leader>bg", function()
  local bg = vim.o.bg == "dark" and "light" or "dark"
  require("nviq.appl.theme").set_theme(bg)
end)

-- Note
kbd("Insert new list item", "i", "<M-CR>", function()
  if not lib.has_filetype("markdown") then
    vim.api.nvim_input("<C-O>o")
    return
  end

  local note = require("nviq.util.note")

  local region = note.ListItemRegion.get(0)

  if not region then
    vim.api.nvim_input("<C-O>o")
    return
  end

  local new_bullet = region.bullet
  if region.ordered then
    new_bullet = note.md_bullet_increment(region.bullet) or region.bullet
  end

  local new_line = string.rep(" ", region.indent) .. new_bullet .. " "
  vim.api.nvim_buf_set_lines(0, region.end_, region.end_, true, { new_line })

  local col = #new_line
  if region.ordered then
    note.md_regen_ordered_list(0, region.end_, { forward_only = true })
    col = vim.api.nvim_buf_get_lines(0, region.end_, region.end_ + 1, true)[1]:len()
  end

  vim.api.nvim_win_set_cursor(0, { region.end_ + 1, col })
end)
kbd("Regenerate bullets for ordered list", "n", "<leader>ml", function()
  if not lib.has_filetype("markdown") then return end
  require("nviq.util.note").md_regen_ordered_list()
end)
