-- No plugins when offline.
if _G.NVIQ.settings.general.offline then return end

local packer = require("nviq.appl.packer")

packer.begin { confirm = false }

require("nviq.pack.ui")
require("nviq.pack.treesitter")
require("nviq.pack.kits")
require("nviq.pack.lsp")
require("nviq.pack.comp")
require("nviq.pack.git")
require("nviq.pack.dap")
require("nviq.pack.dev")
require("nviq.pack.mark")

packer.end_()
