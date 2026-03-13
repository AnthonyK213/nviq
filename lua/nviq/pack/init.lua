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

vim.api.nvim_create_user_command("PacksUpdate", function(tbl)
  local opt = { force = false }
  if #tbl.fargs == 0 then
    vim.pack.update(nil, opt)
  else
    vim.pack.update(tbl.fargs, opt)
  end
end, {
  nargs = "*",
  complete = function()
    local plug_datas = vim.pack.get(nil, { info = false })
    return vim.iter(plug_datas):map(function(plug_data)
      return plug_data.spec.name
    end):totable()
  end,
  desc = "Update packages managed by vim.pack."
})

vim.api.nvim_create_user_command("PacksInfo", function(_)
  packer.info()
end, { desc = "Show information of installed packages." })
