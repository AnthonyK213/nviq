local lib = require("nviq.util.lib")
local kutil = require("nviq.util.k")

local _augroup = vim.api.nvim_create_augroup("nviq.appl", { clear = true })

-- Emacs

require("nviq.appl.emacs")

-- Autopair

require("nviq.appl.autopair").setup {
  pairs = {
    ["()"] = { left = "(", right = ")" },
    ["[]"] = { left = "[", right = "]" },
    ["{}"] = { left = "{", right = "}" },
    ["''"] = { left = "'", right = "'" },
    ['""'] = { left = '"', right = '"' },
    tex_bf = { left = "\\textbf{", right = "}" },
    tex_it = { left = "\\textit{", right = "}" },
    tex_rm = { left = "\\textrm{", right = "}" },
    md_p   = { left = "`", right = "`" },
    md_i   = { left = "*", right = "*" },
    md_b   = { left = "**", right = "**" },
    md_m   = { left = "***", right = "***" },
    md_u   = { left = "<u>", right = "</u>" },
  },
  keymaps = {
    ["("] = { action = "open", pair = "()" },
    [")"] = { action = "close", pair = "()" },
    ["["] = { action = "open", pair = "[]" },
    ["]"] = { action = "close", pair = "[]" },
    ["{"] = { action = "open", pair = "{}" },
    ["}"] = { action = "close", pair = "{}" },
    ["'"] = {
      action = "closeopen",
      pair = {
        ["_"] = "''",
        lisp = "",
        rust = "",
      }
    },
    ['"'] = { action = "closeopen", pair = '""' },
    ["<M-P>"] = {
      action = "closeopen",
      pair = {
        markdown = "md_p",
      }
    },
    ["<M-I>"] = {
      action = "closeopen",
      pair = {
        markdown = "md_i",
        tex = "tex_it",
      }
    },
    ["<M-B>"] = {
      action = "closeopen",
      pair = {
        markdown = "md_b",
        tex = "tex_bf",
      }
    },
    ["<M-N>"] = {
      action = "closeopen",
      pair = {
        markdown = "tex_rm",
        tex = "tex_rm",
      }
    },
    ["<M-M>"] = {
      action = "closeopen",
      pair = {
        markdown = "md_m"
      }
    },
    ["<M-U>"] = {
      action = "closeopen",
      pair = {
        markdown = "md_u"
      }
    },
  }
}

-- Commenting

vim.keymap.set("n", "<leader>kc", function()
  return require("vim._comment").operator() .. "_"
end, { expr = true, desc = "Toggle comment line" })

vim.keymap.set("n", "<leader>ku", function() end)

vim.keymap.set("x", "<leader>kc", function()
  return require("vim._comment").operator()
end, { expr = true, desc = "Toggle comment" })

vim.keymap.set("x", "<leader>ku", function() end)

-- Surrounding

vim.keymap.set({ "n", "x" }, "<leader>sa", function()
  if not vim.bo.modifiable then return end
  local mode = lib.get_mode()
  kutil.to_normal()
  local futures = require("nviq.util.futures")
  futures.spawn(function()
    local left = futures.ui.input { prompt = "Insert surrounding: " }
    if not left then return end
    require("nviq.appl.surround").insert(mode, left, _G.NVIQ.handlers.get_word)
  end)
end, { desc = "Insert surrounding" })

vim.keymap.set("n", "<leader>sd", function()
  if not vim.bo.modifiable then return end
  local futures = require("nviq.util.futures")
  futures.spawn(function()
    local left = futures.ui.input { prompt = "Delete surrounding: " }
    if not left then return end
    require("nviq.appl.surround").delete(left)
  end)
end, { desc = "Delete surrounding" })

vim.keymap.set("n", "<leader>sc", function()
  if not vim.bo.modifiable then return end
  local futures = require("nviq.util.futures")
  futures.spawn(function()
    local old = futures.ui.input { prompt = "Change surrounding: " }
    if not old then return end
    local new = futures.ui.input { prompt = "New surrounding: " }
    if not new then return end
    require("nviq.appl.surround").change(old, new)
  end)
end, { desc = "Change surrounding" })

---
---@param lhs string
---@param pair string|string[]
---@param pattern? string
---@param opts? vim.keymap.set.Opts
local function surround_toggle(lhs, pair, pattern, opts)
  vim.keymap.set({ "n", "x" }, lhs, function()
    local mode = lib.get_mode()
    if mode == lib.Mode.Normal and pattern and require("nviq.util.syntax").Syntax.get():match(pattern) then
      require("nviq.appl.surround").delete(pair)
    else
      kutil.to_normal()
      require("nviq.appl.surround").insert(mode, pair, _G.NVIQ.handlers.get_word)
    end
  end, opts)
end

vim.api.nvim_create_autocmd("FileType", {
  group = _augroup,
  pattern = { "markdown", "vimwiki.markdown" },
  callback = function(event)
    local opts = { buffer = event.buf }
    surround_toggle("<M-P>", "`", [[\v(markdown|Vimwiki)Code|raw]], opts)
    surround_toggle("<M-I>", "*", [[\v(markdown|Vimwiki)Italic|italic]], opts)
    surround_toggle("<M-B>", "**", [[\v(markdown|Vimwiki)Bold|strong]], opts)
    surround_toggle("<M-M>", "***", [[\v(markdown|Vimwiki)BoldItalic|strong|italic]], opts)
    surround_toggle("<M-U>", "<u>", [[\v(html|Vimwiki)Underline]], opts)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = _augroup,
  pattern = "tex",
  callback = function(event)
    local opts = { buffer = event.buf }
    surround_toggle("<M-I>", { "\\textit{", "}" }, [[\vtexStyle(Ital|Both)]], opts)
    surround_toggle("<M-B>", { "\\textbf{", "}" }, [[\vtexStyleBo(ld|th)]], opts)
    surround_toggle("<M-M>", { "\\textrm{", "}" }, [[\vtex(StyleArgConc|MathTextConcArg)]], opts)
  end,
})

-- Bigfile

require("nviq.appl.bigfile").setup {
  max_size        = 1.5 * 1024 * 1024,
  max_line_length = 1024,
}

-- Markdown

---Checks whether `chunk` is a markdown list marker (with a suffix space).
---@param chunk string
---@return boolean
local function is_after_md_list_item(chunk)
  if not chunk then return false end
  return vim.regex([[\v^\s*(\+|-|\*|\d+\.|\w\))(\s\[.\])?\s$]]):match_str(chunk) ~= nil
end

vim.keymap.set("i", "<M-CR>", function()
  if not lib.has_filetype("markdown") then
    kutil.feedkeys("<C-O>o", "in", true)
    return
  end

  local markdown = require("nviq.appl.markdown")

  local region = markdown.ListItemRegion.get(0)

  if not region then
    kutil.feedkeys("<C-O>o", "in", true)
    return
  end

  local new_bullet = region.bullet
  if region.ordered then
    new_bullet = markdown.bullet_increment(region.bullet) or region.bullet
  end

  local new_line = string.rep(" ", region.indent) .. new_bullet .. " "
  vim.api.nvim_buf_set_lines(0, region.end_, region.end_, true, { new_line })

  local col = #new_line
  if region.ordered then
    markdown.regen_ordered_list(0, region.end_, { forward_only = true })
    col = vim.api.nvim_buf_get_lines(0, region.end_, region.end_ + 1, true)[1]:len()
  end

  vim.api.nvim_win_set_cursor(0, { region.end_ + 1, col })
end, { desc = "Insert new list item" })

vim.keymap.set("i", "<Tab>", function()
  if lib.has_filetype("markdown") then
    local back = lib.get_half_line(-1).b
    if is_after_md_list_item(back) then
      kutil.feedkeys("<C-\\><C-O>>>" .. string.rep(kutil.dir_key("r"), vim.bo.tabstop), "in", true)
      return
    end
  end
  kutil.feedkeys("<Tab>", "in", true)
end, { desc = "Indent markdown list item rightwards" })

vim.keymap.set("i", "<S-Tab>", function()
  if lib.has_filetype("markdown") then
    local back = lib.get_half_line(-1).b
    if is_after_md_list_item(back) then
      local indent = vim.fn.indent(".")
      if indent == 0 then return end
      local pos = vim.api.nvim_win_get_cursor(0)
      kutil.feedkeys("<C-\\><C-O><<", "in", true)
      pos[2] = pos[2] - math.min(indent, vim.bo.tabstop)
      vim.api.nvim_win_set_cursor(0, pos)
      return
    end
  end
  kutil.feedkeys("<S-Tab>", "in", true)
end, { desc = "Indent markdown list item leftwards" })

vim.keymap.set("n", "<leader>ml", function()
  if not lib.has_filetype("markdown") then return end
  require("nviq.appl.markdown").regen_ordered_list()
end, { desc = "Regenerate bullets for ordered list" })

-- Evaluate

vim.keymap.set("n", "<leader>el", function()
  local l_lin, l_col, r_lin, r_col = lib.search_pair_pos("(", ")")
  if l_lin < 0 or l_col < 0 or r_lin < 0 or r_col < 0 then return end
  local txt = vim.api.nvim_buf_get_text(0, l_lin, l_col, r_lin, r_col + 1, {})
  local str = table.concat(txt, " ")
  local ok, result = pcall(require("nviq.appl.evaluate").eval, str)
  if not ok then
    lib.warn("Invalid expression")
    return
  end
  vim.api.nvim_buf_set_text(0, l_lin, l_col, r_lin, r_col + 1, { tostring(result) })
end, { desc = "Evaluate lisp expression" })

-- GLSL

vim.api.nvim_create_autocmd("Filetype", {
  group = _augroup,
  pattern = "glsl",
  callback = function(event)
    -- WORKAROUND: `omnifunc` cannot handle `v:lua` with `require`, the module
    -- must be global, or the omnifunc-completion won't work with `i_CTRL-X_CTRL-O`.
    if not _G._NVIQ_APPL_GLSL_OMNIFUNC then
      _G._NVIQ_APPL_GLSL_OMNIFUNC = require("nviq.appl.glsl").omnifunc
    end
    vim.bo[event.buf].omnifunc = "v:lua._NVIQ_APPL_GLSL_OMNIFUNC"
    -- vim.bo[event.buf].omnifunc = "v:lua.require('nviq.appl.glsl').omnifunc"

    vim.b[event.buf].nviq_handler_preview_toggle = require("nviq.appl.glsl").toggle
  end,
})

vim.api.nvim_create_user_command("GlslViewer", function(tbl)
  require("nviq.appl.glsl").start(0, tbl.fargs)
end, { nargs = "*", desc = "Start GlslViewer", complete = "file" })

vim.api.nvim_create_user_command("GlslViewerInput", function(_)
  require("nviq.appl.glsl").input(0)
end, { desc = "GlslViewer input commands" })

-- Marp

vim.api.nvim_create_user_command("MarpToggle", function(_)
  require("nviq.appl.marp").toggle()
end, { desc = "Toggle marp-cli" })

-- Template

vim.api.nvim_create_user_command("CreateProject", function(_)
  require("nviq.appl.template"):create_project()
end, { desc = "Create project with templates" })

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

-- Run

vim.api.nvim_create_user_command("CodeRun", function(tbl)
  local run = require("nviq.appl.run")
  local filetype = vim.bo.filetype
  local recipe = run.get_recipe(filetype)
  if not recipe then
    lib.warn("File type " .. filetype .. " is not supported")
    return
  end
  local option = tbl.args:len() > 0 and tbl.args or 1
  local task = recipe[option]
  if not task then
    lib.warn("Option is invalid")
    return
  end
  run.task_run(task, {
    file_name = vim.api.nvim_buf_get_name(0),
    file_dir  = lib.buf_dir(0),
    file_type = filetype,
  })
end, {
  nargs = "?",
  complete = function()
    local run = require("nviq.appl.run")
    local recipe = run.get_recipe(vim.bo.filetype)
    if not recipe then return {} end
    return run.recipe_get_options(recipe)
  end,
  desc = "Run code in current buffer",
})

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
  local mode = lib.get_mode()
  if mode == lib.Mode.Normal then
    word = NVIQ.handlers.get_word()
  elseif mode == lib.Mode.Visual then
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

-- IME

if _G.NVIQ.settings.general.auto_ime then
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = _augroup,
    callback = function(event)
      local ime = require("nviq.appl.ime")
      vim.b[event.buf].nviq_ime_insert_mode = ime.get()
      ime.set(ime.Layout.US)
    end
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = _augroup,
    callback = function(event)
      local layout = vim.b[event.buf].nviq_ime_insert_mode
      if layout then
        require("nviq.appl.ime").set(layout)
      end
    end
  })
end
