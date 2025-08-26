local lib = require("nviq.util.lib")

-- Vim options.

vim.o.ruler = true
vim.o.number = true
vim.o.hidden = true
vim.o.cursorline = true
vim.o.cmdheight = 1
vim.o.scrolloff = 5
vim.o.laststatus = _G.NVIQ.settings.tui.global_status and 3 or 2
vim.o.winborder = _G.NVIQ.settings.tui.border
vim.o.colorcolumn = "80"
vim.opt.shortmess:append("c")
vim.o.showmode = false
vim.o.showcmd = true
vim.o.list = true
vim.o.listchars = "tab:>-,trail:·"
vim.o.background = "dark"
vim.o.encoding = "utf-8"
vim.o.fencs = "utf-8,chinese,ucs-bom,latin-1,shift-jis,gb18030,gbk,gb2312,cp936"
vim.o.fileformats = "unix,dos,mac"
vim.opt.formatoptions:append("mB")
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.wrap = true
vim.o.linebreak = true
vim.o.showbreak = "^"
vim.o.expandtab = true
vim.o.smarttab = true
vim.o.backspace = "2"
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.errorbells = false
vim.o.visualbell = false
vim.o.winaltkeys = "no"
vim.o.history = 500
vim.o.timeout = false
vim.o.ttimeoutlen = 0
vim.o.hlsearch = true
vim.o.incsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.backup = false
vim.o.writebackup = true
vim.o.swapfile = false
vim.o.undofile = false
vim.o.autoread = true
vim.o.autowrite = true
vim.o.confirm = true

-- Global variables.

vim.g.mapleader = " "

-- Diagnostics

vim.diagnostic.config {
  virtual_text     = true,
  signs            = true,
  underline        = true,
  update_in_insert = false,
  severity_sort    = false,
  float            = {
    border    = _G.NVIQ.settings.tui.border,
    max_width = 80,
  },
}

-- Register handlers.

---@type fun():string,integer,integer Handler to get <cword> which returns the word, start pos (0-based, inclusive) and end pos (0-based, exclusive).
_G.NVIQ.handlers.get_word = lib.get_word

---@type fun(theme:"dark"|"light")|nil Handler to set background theme. Should be registered by colorscheme.
_G.NVIQ.handlers.set_theme = lib.set_theme
