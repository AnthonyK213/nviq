local M = {}

---@type table<string, fun(args:number[]):number>
local _lisp_func_map = {
  ["+"] = function(args)
    local result = 0
    for _, arg in ipairs(args) do
      result = result + arg
    end
    return result
  end,
  ["-"] = function(args)
    local result = args[1]
    if #args == 0 then
      error("Wrong number of arguments.")
    elseif #args == 1 then
      return -result
    else
      for i = 2, #args, 1 do
        result = result - args[i]
      end
      return result
    end
  end,
  ["*"] = function(args)
    local result = 1
    for _, arg in ipairs(args) do
      result = result * arg
    end
    return result
  end,
  ["/"] = function(args)
    local result = args[1]
    if #args == 0 then
      error("Wrong number of arguments.")
    elseif #args == 1 then
      return 1 / result
    else
      for i = 2, #args, 1 do
        result = result / args[i]
      end
      return result
    end
  end,
}

---@class nviq.util.eval.AstNode
---@field m_value string
---@field m_child nviq.util.eval.AstNode[]
local AstNode = {}

AstNode.__index = AstNode

---
---@param value string
---@return nviq.util.eval.AstNode
function AstNode.new(value)
  local node = {
    m_value = value,
    m_child = {},
  }
  setmetatable(node, AstNode)
  return AstNode
end

function AstNode:is_leaf()
  return #self.m_child == 0
end

function AstNode:insert_child(child)
  table.insert(self.m_child, child)
end

---
---@return number
function AstNode:eval()
  if self:is_leaf() then
    local value = tonumber(self.m_value)
    if not value then
      error("Invalid number")
    end
    return value
  end

  local func = _lisp_func_map[self.m_value]
  if not func then
    error("Invalid function")
  end
  local args = {}
  for i, child in ipairs(self.m_child) do
    args[i] = child:eval()
  end
  return func(args)
end

---@class nviq.util.eval.Ast
---@field private m_root nviq.util.eval.AstNode
local Ast = {}

Ast.__index = Ast

---
---@param chunk string
---@return nviq.util.eval.Ast
function Ast.parse(chunk)
  local pre_parse  = chunk:gsub("[%(%)]", function(s) return " " .. s .. " " end)
  local seg_arr = vim.split(vim.trim(pre_parse), "%s+")

  for _, seg in ipairs(seg_arr) do
    if seg == "(" then
    elseif seg == ")" then
    else
    end
  end

  local ast = {}
  setmetatable(ast, Ast)
  return Ast
end

function Ast:eval()
  return self.m_root:eval()
end

---
---@param chunk string
function M.lisp_eval(chunk)
  local ast = Ast.parse(chunk)
  return ast:eval()
end

return M
