local write_xml = require'luamml-xmlwriter'
local make_root = require'luamml-convert'.make_root
local save_result = require'luamml-tex'.save_result
local store_column = require'luamml-table'.store_column
local store_tag = require'luamml-table'.store_tag
local get_table = require'luamml-table'.get_table

local properties = node.get_properties_table()

local funcid = luatexbase.new_luafunction'__luamml_array_add_list_to_row:'
token.set_lua('__luamml_array_add_list_to_row:', funcid, 'protected')
lua.get_functions_table()[funcid] = function()
  -- TODO: Error handling etc
  -- local box = token.scan_int()
  local startmath
  local preskip
  local postskip
  local prestretch = 0 -- Not one since overflowing content protrudes right
  local stretch = {0, 0, 0, 0, 0}
  local n = tex.nest.top.head.next
  local func, ctx, n = node.traverse(tex.nest.top.head.next)
  while true do
    local id, sub n, id, sub = func(ctx, n)
    if not n then break end
    if node.id'math' == id then
      if sub == 0 then
        if startmath then
          texio.write_nl'Multiple formulas detected in array field'
        end
        startmath = n
        for i=2, 5 do
          if stretch[i] ~= 0 then
            prestretch = i
          end
        end
        n = node.end_of_math(n)
      end
    elseif node.id'glue' == id then
      stretch[n.stretch_order+1] = stretch[n.stretch_order+1] + n.stretch
    elseif node.id'rule' == id then
    else
      texio.write_nl'Foreign nodes detected in array field'
    end
  end
  if startmath then
    local poststretch
    for i=1, 5 do
      if stretch[i] ~= 0 then
        poststretch = i
      end
    end
    store_column(startmath).columnalign = prestretch < poststretch and 'left' or prestretch > poststretch and 'right' or nil -- or 'center' -- center is already default
  else
    texio.write_nl'Formula missing in array field'
  end
end

local saved_array

funcid = luatexbase.new_luafunction'__luamml_array_finalize_array:'
token.set_lua('__luamml_array_save_array:', funcid)
lua.get_functions_table()[funcid] = function()
  -- TODO: Error handling etc.
  local colsep = tex.dimen['col@sep']
  saved_array = get_table()
  if colsep ~= 0 then
    saved_array = {[0] = 'mpadded',
      width = string.format('%+.3fpt', 2*colsep/65781.76),
      lspace = string.format('%+.3fpt', colsep/65781.76),
      saved_array
    }
  end
end

funcid = luatexbase.new_luafunction'__luamml_array_finalize_array:'
token.set_lua('__luamml_array_finalize_array:', funcid)
lua.get_functions_table()[funcid] = function()
  -- TODO: Error handling etc.
  local nucl = tex.nest.top.tail.nucleus
  local props = properties[nucl]
  if not props then
    props = {}
    properties[nucl] = props
  end
  props.mathml_table = saved_array
  saved_array = nil
end
