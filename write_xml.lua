-- FIXME: Not sure yet if this will be needed
local function escape_name(name)
  return name
end

-- FIXME: Not sure yet if this will be needed
local escapes = {
  ['"'] = "&quot;",
  ['<'] = "&lt;",
  ['>'] = "&gt;",
  ['&'] = "&amp;",
}
local function escape_text(text)
  return string.gsub(tostring(text), '("<>&)', escapes)
end

local function write_elem(tree, indent)
  if not tree[0] then print('ERR', require'inspect'(tree)) end
  local escaped_name = escape_name(assert(tree[0]))
  local out = "<" .. escaped_name
  if indent then out = indent .. out end
  for attr, val in next, tree do if type(attr) == 'string' then
    out = out .. ' ' .. escape_name(attr) .. '="' .. escape_text(val) .. '"'
  end end
  if not tree[1] then
    return out .. '/>'
  end
  out = out .. '>'
  local inner_indent = indent and indent .. '  '
  for _, elem in ipairs(tree) do
    if type(elem) == 'string' then
      if inner_indent then
        out = out .. inner_indent
      end
      out = out .. escape_text(elem)
    else
      out = out .. write_elem(elem, inner_indent)
    end
  end
  if indent then out = out .. indent end
  return out .. '</' .. escaped_name .. '>'
end

return write_elem
