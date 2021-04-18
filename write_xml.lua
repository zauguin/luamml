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
  return text:gsub('("<>&)', escapes)
end

local function write_elem(tree)
  if not tree[0] then print('ERR', require'inspect'(tree)) end
  local escaped_name = escape_name(assert(tree[0]))
  local out = "<" .. escaped_name
  for attr, val in next, tree do if type(attr) == 'string' then
    out = out .. ' ' .. escape_name(attr) .. '="' .. escape_text(val) .. '"'
  end end
  if not tree[1] then
    return out .. '/>'
  end
  out = out .. '>'
  for _, elem in ipairs(tree) do
    if type(elem) == 'string' then
      out = out .. escape_text(elem)
    else
      out = out .. write_elem(elem)
    end
  end
  return out .. '</' .. escaped_name .. '>'
end

return write_elem
