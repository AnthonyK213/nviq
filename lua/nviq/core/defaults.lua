local lib = require("nviq.util.lib")

-- Source basics.vim.
lib.vim_source("viml/basics")

vim.g.mapleader = " "

-- Status line.
if _G.NVIQ.settings.tui.global_statusline then
  vim.o.laststatus = 3
end

-- Register handlers.

---@type fun():string,integer,integer Handler to get <cword> which returns the word, start pos (0-based, inclusive) and end pos (0-based, exclusive)
_G.NVIQ.handlers.get_word = lib.get_word
