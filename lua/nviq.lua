require("nviq.core")

if vim.g.vscode then
  require("nviq.appl.vscode")
elseif _G.NVIQ.settings.general.offline then
  require("nviq.appl.offline")
else
  require("nviq.pack")
end
