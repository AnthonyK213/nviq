require("nviq.core")
require("nviq.appl")

if vim.g.vscode then
  require("nviq.appl.vscode")
elseif _G.NVIQ.settings.general.offline then
  require("nviq.appl.offline")
  require("nviq.appl.lsp").setup()
else
  require("nviq.pack")
  require("nviq.appl.lsp").setup()
end
