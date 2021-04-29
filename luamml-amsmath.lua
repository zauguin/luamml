local write_xml = require'luamml-xmlwriter'
local make_root = require'luamml-convert'.make_root
local save_result = require'luamml-tex'.save_result
local store_column = require'luamml-table'.store_column
local store_tag = require'luamml-table'.store_tag
local get_table = require'luamml-table'.get_table

local properties = node.get_properties_table()

local funcid = luatexbase.new_luafunction'__luamml_amsmath_add_box_to_row:'
token.set_lua('__luamml_amsmath_add_box_to_row:', funcid, 'protected')
lua.get_functions_table()[funcid] = function()
  -- TODO: Error handling etc
  -- local box = token.scan_int()
  local boxnum = 0
  local startmath = tex.box[boxnum].list
  assert(startmath.id == node.id"math")
  store_column(startmath, true)
end

funcid = luatexbase.new_luafunction'__luamml_amsmath_finalize_table:'
token.set_lua('__luamml_amsmath_finalize_table:', funcid)
lua.get_functions_table()[funcid] = function()
  -- TODO: Error handling etc
  local mml_table = get_table()
  if not mml_table then return end
  mml_table.displaystyle = true
  local columns = node.count(node.id'align_record', tex.lists.align_head)//2
  mml_table.columnalign = string.rep('right left', columns, ' ')
  local spacing = {}
  for n in node.traverse_id(node.id'glue', tex.lists.align_head) do
    spacing[#spacing+1] = n.width == 0 and '0' or '.8em'
  end
  mml_table.columnspacing = table.concat(spacing, ' ', 2, #spacing-2)
  save_result(mml_table, 0)
end

local last_tag

funcid = luatexbase.new_luafunction'__luamml_amsmath_save_tag:'
token.set_lua('__luamml_amsmath_save_tag:', funcid, 'protected')
lua.get_functions_table()[funcid] = function()
  local nest = tex.nest.top
  local chars = {}
  for n, id, sub in node.traverse(nest.head.next) do
    if id == node.id'glyph' then
      if sub >= 0x100 then
        texio.write_nl'WARNING: Already shaped glyph detected in tag. This might lead to wrong output.'
      end
      chars[#chars+1] = n.char
    elseif id == node.id'glue' then
      chars[#chars+1] = 0x20
    elseif id == node.id'kern' then
    else
      texio.write_nl'WARNING: Unsupported node in tag dropped'
    end
  end
  last_tag = utf8.char(table.unpack(chars))
end

funcid = luatexbase.new_luafunction'__luamml_amsmath_set_tag:'
token.set_lua('__luamml_amsmath_set_tag:', funcid, 'protected')
lua.get_functions_table()[funcid] = function()
  if not last_tag then
    texio.write_nl'WARNING: Tag extraction failed'
    return
  end
  store_tag({[0] = 'mtd', {[0] = 'mtext', last_tag}})
  last_tag = nil
end
