local cmd = vim.api.nvim_create_user_command

cmd("BuildCrates", function(tbl)
  local rsmod = require("nviq.appl.rsmod")
  local crates = rsmod.find_crates()
  local args = tbl.args
  if args:len() == 0 then
    rsmod.build_crates(crates)
  elseif crates[args] then
    rsmod.build_crates { [args] = crates[args] }
  else
    vim.notify("Crate was not found")
  end
end, {
  nargs = "?",
  complete = function()
    local crates = require("nviq.appl.rsmod").find_crates()
    return vim.tbl_keys(crates)
  end,
  desc = "Build crates in this configuration"
})

cmd("CreateProject", function(_)
  require("nviq.util.template"):create_project()
end, { desc = "Create project with templates" })

cmd("NvimUpgrade", function(tbl)
  if not _G.NVIQ.settings.general.upgrade then
    vim.notify("NvimUpgrade is disabled", vim.log.levels.WARN)
    return
  end
  require("nviq.appl.upgrade").nvim_upgrade(tbl.args)
end, {
  nargs = "?",
  complete = function() return { "stable", "nightly" } end,
  desc = "Upgrade Neovim by channel"
})
