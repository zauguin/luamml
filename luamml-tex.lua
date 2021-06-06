local mlist_to_mml = require'luamml-convert'
local process_mlist = mlist_to_mml.process
local make_root = mlist_to_mml.make_root
local register_family = mlist_to_mml.register_family
local register_text_family = mlist_to_mml.register_text_family

local mappings = require'luamml-legacy-mappings'
local write_xml = require'luamml-xmlwriter'
local write_struct = require'luamml-structelemwriter'

local filename_token = token.create'l__luamml_filename_tl'

local properties = node.get_properties_table()

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

local funcid = luatexbase.new_luafunction'RegisterFamilyMapping'
token.set_lua('RegisterTextFamily', funcid, 'protected')
lua.get_functions_table()[funcid] = function()
  local fam = token.scan_int()
  local kind = token.scan_string()
  register_text_family(fam, kind)
end

local function shallow_copy(t)
  local tt = {}
  for k,v in next, t do
    tt[k] = v
  end
  return tt
end

-- Possible flag values:
--   0: Normal (This is the only supported one in display mode)
--   1: Like 0, result is display math
--   2: Generate MathML, but only save it for later usage in startmath node
--   3: Skip
--   8: Generate MathML structure elements
--
--  In other words:
--    Bit 1: Suppress output
--    Bit 0: Force display if 1 isn't set, if it is then skip MathML generation

local mlist_result, mlist_display

local undefined_cmd = token.command_id'undefined_cs'
local call_cmd = token.command_id'call'

local function save_result(xml, display)
  mlist_result, mlist_display = xml, display
  token.put_next(filename_token)
  local filename = token.scan_argument()
  local tracing = tex.count.tracingmathml > 1
  local xml_root = (filename ~= '' or tracing) and make_root(shallow_copy(xml), display and 0 or 2)
  if filename ~= '' then
    assert(io.open(filename, 'w'))
      :write(write_xml(xml_root, true):sub(2) .. '\n')
      :close()
  end
  if tracing then
    -- Here xml gets wrapped in an mrow to avoid modifying it.
    texio.write_nl(write_xml(xml_root) .. '\n')
  end
end

luatexbase.add_to_callback('pre_mlist_to_hlist_filter', function(mlist, style)
  local flag = tex.count.l__luamml_flag_int
  if flag & 3 == 3 then
    return true
  end
  local xml, core = process_mlist(mlist, style == 'display' and 0 or 2)
  if flag & 2 == 0 then
    save_result(xml, style == 'display' or flag & 1 == 1)
  end
  if flag & 8 == 8 then
    write_struct(make_root(shallow_copy(xml), (style == 'display' or flag & 1 == 1) and 0 or 2))
  end
  if style == 'text' then
    local startmath = tex.nest.top.tail
    local props = properties[startmath]
    if not props then
      props = {}
      properties[startmath] = props
    end
    props.saved_mathml_table, props.saved_mathml_core = xml, core
  end
  return true
end, 'dump_list')

funcid = luatexbase.new_luafunction'luamml_get_last_mathml_stream:e'
token.set_lua('luamml_get_last_mathml_stream:e', funcid)
lua.get_functions_table()[funcid] = function()
  if not mlist_result then
    tex.error('No current MathML data', {
        "I was asked to provide MathML code for the last formula, but there weren't any new formulas since you last asked."
      })
  end
  local mml = write_xml(make_root(mlist_result, mlist_display and 0 or 2))
  if tex.count.tracingmathml == 1 then
    texio.write_nl(mml .. '\n')
  end
  tex.sprint(-2, tostring(pdf.immediateobj('stream', mml, '/Subtype/application#2Fmathml+xml' .. token.scan_argument(true))))
  mlist_result = nil
end

return {
  save_result = save_result,
}
