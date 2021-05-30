local properties = node.get_properties_table()
local if_vertical = token.create'ifv@'
local if_horizontal = token.create'ifh@'
local iftrue_index = token.create'iftrue'.index

local funcid = luatexbase.new_luafunction'__luamml_kernel_finalize_phantom:N'
token.set_lua('__luamml_kernel_finalize_phantom:N', funcid, 'protected')
lua.get_functions_table()[funcid] = function()
  -- TODO: Error handling etc
  -- At this point, box 0 contains the inner expression and the curent list ends with the noad whose nucleus should get replaced
  local size = token.scan_int()//2
  local boxnum = 0
  local startmath = tex.box[boxnum].list
  assert(startmath.id == node.id"math")
  local nucl = assert(tex.nest.top.tail.nucleus)
  local props = properties[nucl]
  if not props then -- very likely
    props = {}
    properties[nucl] = props
  end
  assert(not props.mathml_table)
  local saved_props = assert(properties[startmath])
  local saved_core = saved_props.saved_mathml_core
  local saved = assert(saved_props.saved_mathml_table or saved_core)
  if saved[0] == 'mstyle'
      and (not saved.displaystyle or saved.displaystyle == (size == 0))
      and (not saved.scriptlevel or saved.scriptlevel == (size == 0 and 0 or size-1))
      then
    saved[0], saved.displaystyle, saved.scriptlevel = 'mphantom', nil, nil
  elseif saved[0] == 'mrow' then
    saved[0] = 'mphantom'
  else
    saved = {[0] = 'mphantom', saved}
  end
  -- The following could be optimized for the case that both if_vertical and if_horizontal
  -- are set, but that should't happen ayway and is just supported for consistency.
  if if_vertical.index ~= iftrue_index then
    saved = {[0] = 'mpadded', height = 0, depth = 0, saved}
  end
  if if_horizontal.index ~= iftrue_index then
    saved = {[0] = 'mpadded', width = 0, saved}
  end
  props.mathml_table, props.mathml_core = saved, saved_core
end
