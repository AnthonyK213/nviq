---@enum nviq.collections.RbNode.Color
local Color = {
  Red   = 0,
  Black = 1,
}

-- FIXME: This should just be `nil`...
local NIL = { color = Color.Black }

---@class nviq.collections.RbNode
---@field key any
---@field value any
---@field left nviq.collections.RbNode
---@field right nviq.collections.RbNode
---@field parent nviq.collections.RbNode
---@field color nviq.collections.RbNode.Color

---
---@param key any
---@param value any
---@return nviq.collections.RbNode
local function rb_node_new(key, value)
  return {
    key = key,
    value = value,
    left = NIL,
    right = NIL,
    parent = NIL,
  }
end

---Determine whether node is a nil node or not.
---@param node nviq.collections.RbNode
---@return boolean
local function rb_node_is_nil(node)
  return node == NIL
end

---@class nviq.collections.RbTree<K, V> : { [K]: V }
---@field private m_root nviq.collections.RbNode
---@operator call:nviq.collections.RbTree
local RbTree = {}

---@private
RbTree.__index = RbTree

setmetatable(RbTree, {
  __call = function(o)
    return o.new()
  end
})

---Create an empty red-black tree.
---@return nviq.collections.RbTree
function RbTree.new()
  local rb_tree = {
    m_root = NIL,
  }
  setmetatable(rb_tree, RbTree)
  return rb_tree
end

---@private
---Left rotation.
---@param node nviq.collections.RbNode
function RbTree:_rotate_left(node)
  local right = node.right
  node.right = right.left
  if not rb_node_is_nil(right.left) then
    right.left.parent = node
  end
  local parent = node.parent
  right.parent = parent
  if rb_node_is_nil(parent) then
    self.m_root = right
  elseif node == parent.left then
    parent.left = right
  else
    parent.right = right
  end
  right.left = node
  node.parent = right
end

---@private
---Right rotation.
---@param node nviq.collections.RbNode
function RbTree:_rotate_right(node)
  local left = node.left
  node.left = left.right
  if not rb_node_is_nil(left.right) then
    left.right.parent = node
  end
  local parent = node.parent
  left.parent = parent
  if rb_node_is_nil(parent) then
    self.m_root = left
  elseif node == parent.right then
    parent.right = left
  else
    parent.left = left
  end
  left.right = node
  node.parent = left
end

---@private
---Transplant.
---@param u nviq.collections.RbNode
---@param v nviq.collections.RbNode
function RbTree:_transplant(u, v)
  if rb_node_is_nil(u.parent) then
    self.m_root = v
  elseif u == u.parent.left then
    u.parent.left = v
  else
    u.parent.right = v
  end
  v.parent = u.parent
end

---@private
---Minimum.
---@param node nviq.collections.RbNode
function RbTree:_minimum(node)
  while not rb_node_is_nil(node.left) do
    node = node.left
  end
  return node
end

---@private
---Get node by `key`.
---@param key any
---@return (nviq.collections.RbNode)?
function RbTree:_get_node(key)
  local node = self.m_root
  while not rb_node_is_nil(node) do
    if key < node.key then
      node = node.left
    elseif key == node.key then
      return node
    else
      node = node.right
    end
  end
end

---@private
---Insert a node.
---@param node nviq.collections.RbNode
function RbTree:_insert_node(node)
  local x, y = self.m_root, NIL
  while not rb_node_is_nil(x) do
    y = x
    if node.key < x.key then
      x = x.left
    else
      x = x.right
    end
  end
  node.parent = y
  if rb_node_is_nil(y) then
    self.m_root = node
  elseif node.key < y.key then
    y.left = node
  else
    y.right = node
  end
  node.left = NIL
  node.right = NIL
  node.color = Color.Red

  while node.parent.color == Color.Red do
    if node.parent == node.parent.parent.left then
      y = node.parent.parent.right
      if y.color == Color.Red then
        node.parent.color = Color.Black
        y.color = Color.Black
        node.parent.parent.color = Color.Red
        node = node.parent.parent
      elseif node == node.parent.right then
        node = node.parent
        self:_rotate_left(node)
      else
        node.parent.color = Color.Black
        node.parent.parent.color = Color.Red
        self:_rotate_right(node.parent.parent)
      end
    else
      y = node.parent.parent.left
      if y.color == Color.Red then
        node.parent.color = Color.Black
        y.color = Color.Black
        node.parent.parent.color = Color.Red
        node = node.parent.parent
      elseif node == node.parent.left then
        node = node.parent
        self:_rotate_right(node)
      else
        node.parent.color = Color.Black
        node.parent.parent.color = Color.Red
        self:_rotate_left(node.parent.parent)
      end
    end
  end

  self.m_root.color = Color.Black
end

---@private
---Delete a node.
---@param node nviq.collections.RbNode
function RbTree:_delete_node(node)
  local x, y = nil, node
  local y_original_color = y.color
  if rb_node_is_nil(node.left) then
    x = node.right
    self:_transplant(node, node.right)
  elseif rb_node_is_nil(node.right) then
    x = node.left
    self:_transplant(node, node.left)
  else
    y = self:_minimum(node.right)
    y_original_color = y.color
    x = y.right
    if y.parent == node then
      x.parent = y
    else
      self:_transplant(y, y.right)
      y.right = node.right
      y.right.parent = y
    end
    self:_transplant(node, y)
    y.left = node.left
    y.left.parent = y
    y.color = node.color
  end
  if y_original_color == Color.Black then
    while x ~= self.m_root and x.color == Color.Black do
      if x == x.parent.left then
        local w = x.parent.right
        if w.color == Color.Red then
          w.color = Color.Black
          x.parent.color = Color.Red
          self:_rotate_left(x.parent)
          w = x.parent.right
        elseif w.left.color == Color.Black and w.right.color == Color.Black then
          w.color = Color.Red
          x = x.parent
        elseif w.right.color == Color.Black then
          w.left.color = Color.Black
          w.color = Color.Red
          self:_rotate_right(w)
          w = x.parent.right
        else
          w.color = x.parent.color
          x.parent.color = Color.Black
          w.right.color = Color.Black
          self:_rotate_left(x.parent)
          x = self.m_root
        end
      else
        local w = x.parent.left
        if w.color == Color.Red then
          w.color = Color.Black
          x.parent.color = Color.Red
          self:_rotate_right(x.parent)
          w = x.parent.left
        elseif w.right.color == Color.Black and w.left.color == Color.Black then
          w.color = Color.Red
          x = x.parent
        elseif w.left.color == Color.Black then
          w.right.color = Color.Black
          w.color = Color.Red
          self:_rotate_left(w)
          w = x.parent.left
        else
          w.color = x.parent.color
          x.parent.color = Color.Black
          w.left.color = Color.Black
          self:_rotate_right(x.parent)
          x = self.m_root
        end
      end
    end
    x.color = Color.Black
  end
end

---Get `value` by `key`.
---@param key any
---@return any
function RbTree:get(key)
  local node = self:_get_node(key)
  if node then
    return node.value
  end
end

---Add a pair of key & value.
---@param key any
---@param value any
---@return boolean
function RbTree:add(key, value)
  if not self:_get_node(key) then
    self:_insert_node(rb_node_new(key, value))
    return true
  end
  return false
end

---Remove a node by `key`.
---@param key any
---@return boolean
---@return any
function RbTree:remove_at(key)
  local node = self:_get_node(key)
  if node then
    self:_delete_node(node)
    return true, node.value
  end
  return false
end

---@private
---Returns the depth of the node.
---@param node nviq.collections.RbNode
---@return integer
function RbTree:_node_depth(node)
  if rb_node_is_nil(node) then
    return -1
  end

  local depth = 0
  while node ~= self.m_root do
    node = node.parent
    depth = depth + 1
  end
  return depth
end

---@private
---To string.
---@return string
function RbTree:__tostring()
  ---@type integer[][]
  local layout = {}

  local right_stack = require("nviq.util.collections.stack")(self.m_root)

  local node_index = 1

  ---@type nviq.collections.RbNode[]
  local node_list = {}

  ---@type integer[]
  local path_cur = {}

  local node_cur = self.m_root

  while not rb_node_is_nil(node_cur) or right_stack:count() > 0 do
    if rb_node_is_nil(node_cur) then
      node_cur = right_stack:pop()
    else
      table.insert(path_cur, node_index)
      node_list[node_index] = node_cur
      node_index = node_index + 1

      if not rb_node_is_nil(node_cur.right) then
        right_stack:push(node_cur.right)
      end

      node_cur = node_cur.left
      if rb_node_is_nil(node_cur) then
        table.insert(layout, path_cur)
        path_cur = {}
      end
    end
  end

  local result = { string.format("RbTree<%p>", self) }

  if node_index > 0 then
    local node_width = #tostring(node_index - 1) + 1

    for _, path in ipairs(layout) do
      local line = {}
      local node_first = node_list[path[1]]
      local depth = self:_node_depth(node_first)
      local indent = (node_width + 2) * depth
      for _, index in ipairs(path) do
        local color = node_list[index].color == Color.Black and "B" or "R"
        table.insert(line, color .. require("nviq.util.s").zfill(tostring(index), node_width - 1))
      end
      table.insert(result, string.rep(" ", indent) .. table.concat(line, "──"))
    end
  end

  for index, node in ipairs(node_list) do
    table.insert(result, string.format("[%d] %s : %s", index, node.key, node.value))
  end

  return table.concat(result, "\n")
end

return RbTree
