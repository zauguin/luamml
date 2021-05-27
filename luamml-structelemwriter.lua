local struct_begin = token.create'tag_struct_begin:n'
local struct_use = token.create'tag_struct_use:n'
local struct_end = token.create'tag_struct_end:'

local mc_begin = token.create'tag_mc_begin:n'
local mc_end = token.create'tag_mc_end:'

local function escape_name(name)
  return name
end

local function escape_string(str)
  return str
end

local mathml_ns_obj
local function get_mathml_ns_obj()
  mathml_ns_obj = mathml_ns_obj or token.create'c__pdf_backend_object_tag/NS/mathml_int'.index
  return mathml_ns_obj
end

local attribute_counter = 0
local attributes = setmetatable({}, {__index = function(t, k)
  attribute_counter = attribute_counter + 1
  local attr_name = string.format('luamml_attr_%i', attribute_counter)
  t[k] = attr_name
  tex.runtoks(function()
    -- tex.sprint(string.format('\\tagpdfsetup{newattribute={%s}{/O/NSO/NS %i 0 R',
    --     attr_name, mathml_ns_obj or get_mathml_ns_obj()))
    tex.sprint(string.format('\\tagpdfsetup{newattribute={%s}{/O/MathML-3',
        attr_name))
    tex.cprint(12, k)
    tex.sprint'}}'
  end)
  return attr_name
end})

local mc_type = token.create'l__tag_mc_type_attr'.index
local mc_cnt = token.create'l__tag_mc_cnt_attr'.index
-- print('!!!', mc_type, mc_cnt)

local attrs = {}
local function write_elem(tree, indent)
  if tree[':struct'] then
    return tex.runtoks(function()
      return tex.sprint(struct_use, '{', tree[':struct'], '}')
    end)
  end
  if not tree[0] then print('ERR', require'inspect'(tree)) end
  local i = 0
  for attr, val in next, tree do if type(attr) == 'string' and not string.find(attr, ':') and attr ~= 'xmlns' then
  -- for attr, val in next, tree do if type(attr) == 'string' and string.byte(attr) ~= 0x3A then
    i = i + 1
    attrs[i] = string.format('/%s(%s)', escape_name(attr), escape_string(val))
  end end
  table.sort(attrs)
  local attr_name
  tex.sprint(struct_begin, '{tag=', tree[0], '/mathml')
  if i ~= 0 then
    tex.sprint(',attribute=', attributes[table.concat(attrs)])
  end
  tex.sprint'}'
  for j = 1, i do attrs[j] = nil end

  if tree[':node'] then
    local n = tree[':node']
    tex.runtoks(function()
      tex.sprint{mc_begin, string.format('{tag=%s}', tree[0])}
      -- NOTE: This will also flush all previous sprint's... That's often annoying, but in this case actually intentional.
    end)
    node.set_attribute(tree[':node'], mc_type, tex.attribute[mc_type])
    node.set_attribute(tree[':node'], mc_cnt, tex.attribute[mc_cnt])
    tex.runtoks(function()
      tex.sprint(mc_end)
    end)
  end
  for _, elem in ipairs(tree) do
    if type(elem) ~= 'string' then
      write_elem(elem)
    end
  end
  tex.runtoks(function()
    tex.sprint(struct_end)
  end)
end

return function(element)
  return write_elem(element)
end
