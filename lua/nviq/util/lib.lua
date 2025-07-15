local futil = require("nviq.util.f")
local putil = require("nviq.util.p")
local sutil = require("nviq.util.s")

local M = {}

local _p_word_first_half = [[\v([\]] .. [[u4e00-\]] .. [[u9fff0-9a-zA-Z_-]+)$]]
local _p_word_last_half = [[\v^([\]] .. [[u4e00-\]] .. [[u9fff0-9a-zA-Z_-])+]]
local _dir_keys = {
  l = "<C-G>U<Left>",
  r = "<C-G>U<Right>",
  u = "<C-G>U<Up>",
  d = "<C-G>U<Down>",
}

---Returns the directory of the buffer with bufnr.
---@param bufnr? integer The buffer number, default 0 (current buffer).
---@return string buf_dir The buffer directory.
function M.buf_dir(bufnr)
  return vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr or 0))
end

---Returns an array of listed buffer handles.
---@return integer[] bufs Loaded buffer handles.
function M.buf_listed()
  return vim.tbl_filter(function(h)
    return vim.api.nvim_buf_is_loaded(h) and vim.bo[h].buflisted
  end, vim.api.nvim_list_bufs())
end

---Extracts the buffer handle.
---@param bufnr? integer
---@return integer
function M.bufnr(bufnr)
  if bufnr == 0 or not bufnr then
    return vim.api.nvim_get_current_buf()
  end
  return bufnr
end

---Returns the key code of direction that won't break the history.
---@param dir "l"|"r"|"u"|"d" Left/Right/Up/Down.
---@return string key_code
function M.dir_key(dir)
  return _dir_keys[dir]
end

---Escapes the termianl codes, feeds them to nvim.
---@see vim.api.nvim_feedkeys
---@param keys string To be typed.
---@param mode string Behavior flags, see **feedkeys()**.
---@param escape_ks boolean If true, escape K_SPECIAL bytes in `keys`.
function M.feedkeys(keys, mode, escape_ks)
  local k = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(k, mode, escape_ks)
end

---Gets the path of the dotfile (.nvimrc, etc.).
---Searching order: stdpath("config") -> home -> ...
---Uses the last one was found.
---@param name string Name of the dotfile (with out '.' or '\_' at the start).
---@return boolean exists True if the option file exists.
---@return string? path Path to the dotfile.
function M.get_dotfile(name)
  local dir_table = {
    vim.fn.stdpath("config"),
    vim.uv.os_homedir(),
  }

  local ok_index = 0
  local file_name

  for i, dir in ipairs(dir_table) do
    ok_index = i
    file_name = "/." .. name
    local file_path = dir .. file_name
    if futil.is_file(file_path) then
      return true, file_path
    elseif putil.os_type() == putil.OS.Windows then
      file_name = "/_" .. name
      file_path = dir .. file_name
      if futil.is_file(file_path) then
        return true, file_path
      end
    end
  end

  if ok_index > 0 then
    return false, dir_table[ok_index] .. file_name
  else
    return false, nil
  end
end

---Returns the visual selections.
---@return string selection Visual selection.
function M.get_gv()
  local mode = vim.api.nvim_get_mode().mode
  local in_vis = vim.list_contains({ "v", "V", "" }, mode)
  local a_bak = vim.fn.getreg("a", 1)
  vim.cmd.normal {
    (in_vis and "" or "gv") .. [["ay]],
    mods = {
      silent = true
    }
  }
  local a_val = vim.fn.getreg("a") --[[@as string]]
  vim.fn.setreg("a", a_bak)
  return a_val
end

---Returns the start and end positions of visual selection.
---@param bufnr? integer Buffer number, default 0 (current buffer).
---@return integer row_s Start row (0-based, inclusive).
---@return integer col_s Start column (0-based, inclusive).
---@return integer row_e End row (0-based, exclusive).
---@return integer col_e End column (0-based, exclusive).
function M.get_gv_mark(bufnr)
  bufnr = bufnr or 0
  local s_pos = vim.api.nvim_buf_get_mark(bufnr, "<")
  local e_pos = vim.api.nvim_buf_get_mark(bufnr, ">")
  local e_len = #vim.api.nvim_buf_get_lines(bufnr, e_pos[1] - 1, e_pos[1], true)[1]

  if e_pos[2] >= e_len then
    e_pos[2] = math.max(0, e_len - 1)
  end

  local e_txt = vim.api.nvim_buf_get_text(bufnr, e_pos[1] - 1, e_pos[2], e_pos[1] - 1, -1, {})[1]
  local d = #sutil.sub(e_txt, 1, 1)

  return s_pos[1] - 1, s_pos[2], e_pos[1] - 1, e_pos[2] + d
end

---Gets backward/forward part of current line around the cursor.
---@param half? -1|0|1 -1: backward part; 0: both parts; 1: forward part.
---@return { b:string, f:string } result *b*: Half line before the cursor; *f*: Half line after the cursor.
function M.get_half_line(half)
  half = half or 0

  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local res = { b = "", f = "" }

  if half <= 0 then
    res.b = line:sub(1, col)
  end

  if half >= 0 then
    res.f = line:sub(col + 1, #line)
  end

  return res
end

---Get the word and its position under the cursor.
---@return string word Word under the cursor.
---@return integer start_column Start index of the line (0-based, inclusive).
---@return integer end_column End index of the line (0-based, exclusive).
function M.get_word()
  local context = M.get_half_line()
  local b = context.b
  local f = context.f
  local s_a, _ = vim.regex(_p_word_first_half):match_str(b)
  local _, e_b = vim.regex(_p_word_last_half):match_str(f)
  local p_a = ""
  local p_b = ""
  if e_b then
    p_a = s_a and b:sub(s_a + 1) or ""
    p_b = f:sub(1, e_b)
  end
  local word = p_a .. p_b
  if word == "" then
    word = M.str_sub(f, 1, 1)
    p_b = word
  end
  return word, #b - #p_a, #b + #p_b
end

---Checks if `filetype` has `target` filetype.
---@param target string Destination file type.
---@param filetype? string File type to be checked, default *filetype* of current buffer.
---@return boolean result True if `filetype` has `target` filetype.
function M.has_filetype(target, filetype)
  filetype = filetype or vim.bo.filetype
  if not filetype then return false end
  return vim.list_contains(vim.split(filetype, "%."), target)
end

---Decodes a json file.
---@param path string Path of file to decode.
---@param loosely? boolean If true, tries to ignore comment lines and trailing commas (not recommended).
---@return 0|1|2 code 0: ok, 1: json is invalid, 2: file does not exist.
---@return table? result Decode result.
function M.json_decode(path, loosely)
  local content = futil.read_all_text(path)
  if not content then
    return 2, nil
  end

  ---@type (fun(chunk: string):string)[]
  local filters = {
    ---Remove comment lines.
    ---@param chunk string
    ---@return string
    function(chunk)
      local lines = vim.split(chunk, "[\n\r]", {
        plain = false,
        trimempty = true,
      })
      return table.concat(vim.tbl_filter(function(v)
        if vim.startswith(vim.trim(v), "//") then
          return false
        end
        return true
      end, lines))
    end,
    ---Remove trailing commas.
    ---@param chunk string
    ---@return string
    ---@return integer
    function(chunk)
      local s = chunk:gsub(",%s*([%]%}])", "%1")
      return s
    end,
  }

  local ok, result;
  local i = 0;
  local n = #filters

  while true do
    ok, result = pcall(vim.json.decode, content)
    if ok then
      return 0, result
    elseif not loosely or i == n then
      break
    end
    i = i + 1
    content = filters[i](content)
  end

  return 1, nil
end

---Creates a new split window.
---@param position "aboveleft"|"belowright"|"topleft"|"botright"
---@param option? { split_size: integer, ratio_max: number, vertical: boolean, hide_number: boolean } Split options:
---  - *split_size*: Split size;
---  - *ratio_max*: real_split_size <= real_win_size \* ratio_max;
---  - *vertical*: If true, split vertically.
---  - *hide_number*: If true, hide line number in split window.
---@return boolean ok True if split window successfully.
---@return integer winnr New split window number, -1 on failure.
---@return integer bufnr New split buffer number, -1 on failure.
function M.new_split(position, option)
  option = option or {}
  if not vim.list_contains({
        "aboveleft", "belowright", "topleft", "botright"
      }, position) then
    M.warn("Invalid position.")
    return false, -1, -1
  end
  local vertical = option.vertical
  if type(vertical) ~= "boolean" then
    vertical = false
  end
  local size_this = vertical and vim.api.nvim_win_get_height(0) or vim.api.nvim_win_get_width(0)
  local split_size = option.split_size
  if type(split_size) ~= "number" or split_size <= 0 then
    split_size = 15
  end
  local ratio_max = option.ratio_max
  if type(ratio_max) ~= "number" or ratio_max <= 0 or ratio_max >= 1 then
    ratio_max = 0.382
  end
  local hide_number = option.hide_number
  if type(hide_number) ~= "boolean" then
    hide_number = true
  end
  local term_size = math.min(split_size, math.floor(size_this * ratio_max))
  vim.cmd.new {
    mods = {
      split = position,
      vertical = vertical,
    }
  }
  if hide_number then
    vim.api.nvim_set_option_value("number", false, {
      scope = "local",
      win = 0,
    })
  end
  if vertical then
    vim.api.nvim_win_set_width(0, term_size)
  else
    vim.api.nvim_win_set_height(0, term_size)
  end
  return true, vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
end

---Locates surrounding pair in direction `dir`. Returns -1 when not found.
---CAVEATS: This function won't check the syntax, so imbalanced pairs in a string
---won't be handled correctly.
---@param left string Left part of the pair.
---@param right string Right part of the pair.
---@return integer l_lin Line number of the left pair pos (0-based).
---@return integer l_col Column number of the left pair pos (0-based).
---@return integer r_lin Line number of the right pair pos (0-based).
---@return integer r_col Column number of the right pair pos (0-based).
function M.search_pair_pos(left, right)
  if left == right then
    local pat = "\\v" .. M.vim_pesc(left)
    local l_lin, l_col = unpack(vim.fn.searchpos(pat, "nbW"))
    local r_lin, r_col = unpack(vim.fn.searchpos(pat, "ncW"))
    return l_lin - 1, l_col - 1, r_lin - 1, r_col - 1
  else
    local l_pat = "\\v" .. M.vim_pesc(left)
    local r_pat = "\\v" .. M.vim_pesc(right)
    local l_lin, l_col = unpack(vim.fn.searchpairpos(l_pat, "", r_pat, "nbW"))
    local r_lin, r_col = unpack(vim.fn.searchpairpos(l_pat, "", r_pat, "ncW"))
    return l_lin - 1, l_col - 1, r_lin - 1, r_col - 1
  end
end

---Sets background theme.
---@param theme "dark"|"light"
function M.set_theme(theme)
  if vim.o.background ~= theme then
    vim.o.background = theme
  end
end

---Try-Catch-Finally.
---@param try_block function
---@return { catch: fun(catch_block: fun(ex: string)):{ finally: fun(finally_block: function) }, finally: fun(finally_block: function) }
function M.try(try_block)
  local status, err = true, nil

  if type(try_block) == "function" then
    status, err = xpcall(try_block, debug.traceback)
  end

  ---Finally.
  ---@param finally_block function
  ---@param catch_block_declared boolean
  local finally = function(finally_block, catch_block_declared)
    if type(finally_block) == "function" then
      finally_block()
    end

    if not catch_block_declared and not status then
      error(err)
    end
  end

  ---Catch.
  ---@param catch_block fun(ex: string)
  ---@return { finally: fun(finally_block: function) }
  local catch = function(catch_block)
    local catch_block_declared = type(catch_block) == "function"

    if not status and catch_block_declared then
      local ex = err or "Unknown error"
      catch_block(ex)
    end

    return {
      finally = function(finally_block)
        finally(finally_block, catch_block_declared)
      end
    }
  end

  return {
    catch = catch,
    finally = function(finally_block)
      finally(finally_block, false)
    end
  }
end

---Sources a vim file in config directory.
---@param file string Vim script path relative to the config directory.
function M.vim_source(file)
  local file_path = vim.fs.joinpath(vim.fn.stdpath("config"), file .. ".vim")
  if futil.is_file(file_path) then
    vim.cmd.source(file_path)
  else
    vim.notify("" .. file .. ".vim was not found.", vim.log.levels.WARN)
  end
end

---Escapes vim regex(magic) special characters in a pattern by **backslash**.
---@param str string String of vim regex to escape.
---@return string result Escaped string.
function M.vim_pesc(str)
  return vim.fn.escape(str, " ()[]{}<>.+*^$")
end

---Notifies a warning message.
---@param msg string The message.
function M.warn(msg)
  vim.notify(msg, vim.log.levels.WARN, nil)
end

return M
