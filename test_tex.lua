local inspect = require'inspect'
local function show(t) return print(inspect(t)) end

local mlist_to_table = require'mlist_to_mml'
local write_xml = require'write_xml'

luatexbase.add_to_callback('pre_mlist_to_hlist_filter', function(mlist, style)
  print'\n\n'
  local xml = mlist_to_table(mlist, style == 'display' and 2 or 0)
  print(write_xml(xml))
  -- print(write_xml(xml, '\n'))
  print'\n'
  return true
end, 'dump_list')
