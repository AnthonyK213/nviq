local M = {}

function M.setup()
  vim.treesitter.language.register("powershell", "ps1")

  ---@type string[]?
  local parsers = vim.tbl_get(_G.NVIQ.settings, "ts", "parsers")
  if not parsers then return end

  local filetypes = {}
  for _, parser in ipairs(parsers) do
    local langs = vim.treesitter.language.get_filetypes(parser)
    for _, lang in ipairs(langs) do
      table.insert(filetypes, lang)
    end
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("nviq.appl.treesitter", { clear = true }),
    pattern = filetypes,
    callback = function()
      pcall(function()
        vim.treesitter.start()
        vim.wo.foldexpr = [[v:lua.vim.treesitter.foldexpr()]]
        vim.bo.indentexpr = [[v:lua.require("nvim-treesitter").indentexpr()]]
      end)
    end,
  })
end

return M
