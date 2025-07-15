if not vim.g.vscode then return end

local vscode = require("vscode")

-- Options

vim.o.loadplugins = false

vim.cmd.filetype("on")
vim.cmd.filetype("indent", "off")
vim.cmd.filetype("plugin", "off")
vim.cmd.syntax("off")

vim.o.shada = ""
vim.o.colorcolumn = ""

vim.g.clipboard = vim.g.vscode_clipboard
vim.notify = vscode.notify

-- Mappings

local function kbd(mode, lhs, cmd, block)
  local invoke = block and vscode.call or vscode.action
  local options = {}
  if mode == "v" then
    options.range = {
      vim.api.nvim_buf_get_mark(0, "<")[1] - 1,
      vim.api.nvim_buf_get_mark(0, ">")[1] - 1,
    }
  end
  vim.keymap.set(mode, lhs, function() invoke(cmd, options) end)
end

-- Buffer
kbd("n", "<leader>bd", "workbench.action.closeActiveEditor")
kbd("n", "<leader>bn", "workbench.action.nextEditor")
kbd("n", "<leader>bp", "workbench.action.previousEditor")
-- Find
kbd("n", "<leader>fa", "workbench.action.gotoSymbol")
kbd("n", "<leader>ff", "workbench.action.quickOpen")
kbd("n", "<leader>fg", "workbench.view.search")
-- Fold
kbd("n", "za", "editor.toggleFold")
kbd("n", "zc", "editor.fold")
kbd("n", "zo", "editor.unfold")
kbd("n", "zC", "editor.foldRecursively")
kbd("n", "zM", "editor.foldAll")
kbd("n", "zO", "editor.unfoldRecursively")
kbd("n", "zR", "editor.unfoldAll")
-- Git
kbd("n", "<leader>gj", "workbench.action.editor.nextChange")
kbd("n", "<leader>gk", "workbench.action.editor.previousChange")
kbd("n", "<leader>gn", "workbench.view.scm")
-- Comment
kbd("n", "<leader>kc", "editor.action.addCommentLine")
kbd("n", "<leader>ku", "editor.action.removeCommentLine")
kbd("v", "<leader>kc", "editor.action.addCommentLine")
kbd("v", "<leader>ku", "editor.action.removeCommentLine")
-- Open
kbd("n", "<leader>op", "workbench.action.toggleSidebarVisibility")
kbd("n", "<leader>ot", "workbench.action.terminal.new")
kbd("n", "<leader>ou", "editor.action.openLink")
-- LSP
kbd("n", "K", "editor.action.showHover")
kbd("n", "<leader>la", "editor.action.quickFix")
kbd("n", "<leader>ld", "editor.action.goToDeclaration")
kbd("n", "<leader>lf", "editor.action.revealDefinition")
kbd("n", "<leader>li", "editor.action.goToImplementation")
kbd("n", "<leader>lm", "editor.action.formatDocument")
kbd("n", "<leader>ln", "editor.action.rename")
kbd("n", "<leader>lr", "editor.action.goToReferences")
kbd("n", "<leader>l[", "editor.action.marker.prev")
kbd("n", "<leader>l]", "editor.action.marker.next")
-- MISC
kbd("n", "<leader>mv", "outline.focus")
