local lib = require("nviq.util.lib")
local sutil = require("nviq.util.s")
local tutil = require("nviq.util.t")

local M = {}

local _pairs = {
  ["("] = ")",
  ["["] = "]",
  ["{"] = "}",
  ["<"] = ">",
  [" "] = " ",
}

---Returns the right side of the surrounding pair according to the `left`.
---@param left string
local function get_right(left)
  if left:match("^[%(%[{<%s《“]+$") then
    return table.concat(vim.tbl_map(function(x)
      return _pairs[x]
    end, tutil.reverse(sutil.chars(left))))
  elseif vim.regex([[\v^(\<\w{-}\>)+$]]):match_str(left) then
    return "</" .. table.concat(tutil.reverse(vim.tbl_filter(function(str)
      return str ~= ""
    end, vim.split(left, "<"))), "</")
  else
    return left
  end
end

---Extracts surrounding pair from the input.
---@param pair string|string[] Left|Both side(s) of the surrounding pair.
---@return string? left
---@return string? right
local function extract_pair(pair)
  local left, right

  if type(pair) == "table" then
    left, right = unpack(pair)
  elseif type(pair) == "string" then
    left = pair
    right = get_right(left)
  end

  return left, right
end

---Locates surrounding pair in direction `dir`.
---FIXME: If there are imbalanced pairs in string, how to get this work?
---@param left string
---@param right string
---@return integer l_lin (0-based)
---@return integer l_col (0-based)
---@return integer r_lin (0-based)
---@return integer r_col (0-based)
local function locate_pair(left, right)
  if left == right then
    local pat = "\\v" .. lib.vim_pesc(left)
    local l_lin, l_col = unpack(vim.fn.searchpos(pat, "nbW"))
    local r_lin, r_col = unpack(vim.fn.searchpos(pat, "ncW"))
    return l_lin - 1, l_col - 1, r_lin - 1, r_col - 1
  else
    local l_pat = "\\v" .. lib.vim_pesc(left)
    local r_pat = "\\v" .. lib.vim_pesc(right)
    local l_lin, l_col = unpack(vim.fn.searchpairpos(l_pat, "", r_pat, "nbW"))
    local r_lin, r_col = unpack(vim.fn.searchpairpos(l_pat, "", r_pat, "ncW"))
    return l_lin - 1, l_col - 1, r_lin - 1, r_col - 1
  end
end

---Inserts the input surrounding to the ends of <cword>.
---@param mode "n"|"v" The mode.
---@param pair string|string[] The surrounding pair.
---@param get_word? fun():string,integer,integer Function to get <cword>.
function M.insert(mode, pair, get_word)
  if not pair then return end

  local left, right = extract_pair(pair)
  if not left or not right then return end

  if mode == "n" then
    local _, s, e = (get_word or lib.get_word)()
    local lin, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_text(0, lin - 1, e, lin - 1, e, { right })
    vim.api.nvim_buf_set_text(0, lin - 1, s, lin - 1, s, { left })
    vim.api.nvim_win_set_cursor(0, { lin, col + #left })
  elseif mode == "v" then
    local s_lin, s_col, e_lin, e_col = lib.get_gv_mark()
    vim.api.nvim_buf_set_text(0, e_lin, e_col, e_lin, e_col, { right })
    vim.api.nvim_buf_set_text(0, s_lin, s_col, s_lin, s_col, { left })
  end
end

---Deletes the input surrounding around the cursor.
---@param pair string|string[] The surrounding pair.
function M.delete(pair)
  if not pair then return end

  local left, right = extract_pair(pair)
  if not left or not right then return end

  local l_lin, l_col, r_lin, r_col = locate_pair(left, right)
  if l_lin < 0 or l_col < 0 or r_lin < 0 or r_col < 0 then
    vim.notify("Surrounding not found")
    return
  end

  vim.api.nvim_buf_set_text(0, r_lin, r_col, r_lin, r_col + #right, {})
  vim.api.nvim_buf_set_text(0, l_lin, l_col, l_lin, l_col + #left, {})
end

---Changes surrounding around the cursor.
---@param pair_old string|string[] The surrounding pair to be changed.
---@param pair_new string|string[] The new surrounding pairs.
function M.change(pair_old, pair_new)
  if not pair_old or not pair_new then return end

  local left_old, right_old = extract_pair(pair_old)
  if not left_old or not right_old then return end

  local left_new, right_new = extract_pair(pair_new)
  if not left_new or not right_new then return end

  local l_lin, l_col, r_lin, r_col = locate_pair(left_old, right_old)
  if l_lin < 0 or l_col < 0 or r_lin < 0 or r_col < 0 then
    vim.notify("Surrounding not found")
    return
  end

  vim.api.nvim_buf_set_text(0, r_lin, r_col, r_lin, r_col + #right_old, { right_new })
  vim.api.nvim_buf_set_text(0, l_lin, l_col, l_lin, l_col + #left_old, { left_new })
end

return M
