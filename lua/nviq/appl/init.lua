local lib = require("nviq.util.lib")

-- Theme

require("nviq.appl.theme").set_theme(_G.NVIQ.settings.tui.theme)

-- Jieba

vim.keymap.set("n", "<leader>jm", function()
  local jieba = require("nviq.appl.jieba")
  if jieba.is_enabled() then
    jieba:disable()
    vim.notify("Jieba is disabled")
  else
    if jieba:enable() then
      vim.notify("Jieba is enabled")
    end
  end
end, { desc = "Toggle jieba-mode" })

-- Rust modules

vim.api.nvim_create_user_command("BuildCrates", function(tbl)
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

-- Stardict

vim.keymap.set({ "n", "x" }, "<leader>hh", function()
  local word
  local mode = vim.api.nvim_get_mode().mode
  if mode == "n" then
    word = NVIQ.handlers.get_word()
  elseif vim.list_contains({ "v", "V", "" }, mode) then
    word = lib.get_gv()
  else
    return
  end
  require("nviq.appl.stardict").stardict(word)
end, { desc = "Look up the word under the cursor" })

-- Upgrade

vim.api.nvim_create_user_command("NvimUpgrade", function(tbl)
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
