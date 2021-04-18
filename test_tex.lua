local inspect = require'inspect'
local function show(t) return print(inspect(t)) end

local mlist_to_table = require'mlist_to_mml'
local write_xml = require'write_xml'

luatexbase.add_to_callback('pre_mlist_to_hlist_filter', function(mlist)
  print'\n\n'
  local xml = mlist_to_table(mlist)
  show(write_xml(xml))
  print'\n'
  return true
end, 'dump_list')
