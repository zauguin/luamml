local mlist_to_mml = require'luamml-convert'
local process_mlist = mlist_to_mml.process
local register_family = mlist_to_mml.register_family

local mappings = require'luamml-legacy-mappings'
local write_xml = require'luamml-xmlwriter'

local funcid = luatexbase.new_luafunction'RegisterFamilyMapping'
token.set_lua('RegisterFamilyMapping', funcid, 'protected')
lua.get_functions_table()[funcid] = function()
  local fam = token.scan_int()
  local mapping = token.scan_string()
  if mappings[mapping] then
    register_family(fam, mappings[mapping])
  else
    tex.error(string.format('Unknown font mapping %q', mapping))
  end
end

luatexbase.add_to_callback('pre_mlist_to_hlist_filter', function(mlist, style)
  print''
  local xml = process_mlist(mlist, style == 'display' and 2 or 0)
  print(write_xml(xml))
  -- print(write_xml(xml, '\n'))
  print''
  return true
end, 'dump_list')
