local write_xml = require'luamml-xmlwriter'
local make_root = require'luamml-convert'.make_root

local properties = node.get_properties_table()

local funcid = luatexbase.new_luafunction'luamml_amsmath_add_box_to_row:'
token.set_lua('luamml_amsmath_add_box_to_row:', funcid, 'protected')
lua.get_functions_table()[funcid] = function()
  -- TODO: Error handling etc
  -- local box = token.scan_int()
  local boxnum = 0
  local startmath = tex.box[boxnum].list
  assert(startmath.id == node.id"math")
  local props = assert(properties[startmath])
  local mml = assert(props.saved_mathml_table)
  props.saved_mathml_table = nil
  table.insert(mml, 1, {[0] = 'maligngroup'})
  if mml[0] == 'mstyle' and mml.displaystyle == true then
    mml[0], mml.displaystyle, mml.scriptlevel = 'mtd', nil, nil
  else
    if mml[0] ~= 'mstyle' then
      mml = {[0] = 'mstyle', displaystyle = false, mml}
    end
    mml = {[0] = 'mtd', mml}
  end
  local row_temp = tex.nest[tex.nest.ptr-1]
  props = properties[row_temp]
  if not props then
    props = {}
    properties[row_temp] = props
  end
  if not props.mathml_row then
    props.mathml_row = {[0] = 'mtr'}
  end
  mml_row = props.mathml_row
  table.insert(mml_row, mml)
end

local funcid = luatexbase.new_luafunction'luamml_amsmath_finalize_row:'
token.set_lua('luamml_amsmath_finalize_row:', funcid, 'protected')
lua.get_functions_table()[funcid] = function()
  -- TODO: Error handling etc
  local row_temp = tex.nest[tex.nest.ptr-1]
  local props = properties[row_temp]
  if not props then return end
  if not props.mathml_row then return end
  mml_row = props.mathml_row
  props.mathml_row = nil
  props = properties[tex.lists.align_head]
  if not props then
    props = {}
    properties[tex.lists.align_head] = props
  end
  local mml_table = props.mathml_table_node_table
  if not mml_table then
    mml_table = {[0] = 'mtable', displaystyle = true}
    props.mathml_table_node_table = mml_table
  end
  table.insert(mml_table, mml_row)
end

local funcid = luatexbase.new_luafunction'luamml_amsmath_finalize_table:'
token.set_lua('luamml_amsmath_finalize_table:', funcid)
lua.get_functions_table()[funcid] = function()
  -- TODO: Error handling etc
  local props = properties[tex.lists.align_head]
  if not props then return end
  local mml_table = props.mathml_table_node_table
  props.mathml_table_node_table = nil
  if not mml_table then return end
  print(write_xml(make_root(mml_table, 0)))
end

funcid = luatexbase.new_luafunction'luamml_last_math_alignmark:'
token.set_lua('luamml_last_math_alignmark:', funcid, 'protected')
lua.get_functions_table()[funcid] = function()
  local n = tex.nest.top.tail
  n = n.nucleus or n
  local props = properties[n]
  if not props then
    props = {}
    properties[n] = props
  end
  props.mathml_table = {[0] = 'malignmark'}
end
