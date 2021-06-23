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
local mmode, hmode, vmode do
  local result, input = {}, tex.getmodevalues()
  for k,v in next, tex.getmodevalues() do
    if v == 'math' then mmode = k
    elseif v == 'horizontal' then hmode = k
    elseif v == 'vertical' then vmode = k
    else assert(v == 'unset')
    end
  end
  assert(mmode and hmode and vmode)
end

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
--   0: Skip
--   1: Generate MathML, but only save it for later usage in startmath node
--   3: Normal (This is the only supported one in display mode)
--  11: Generate MathML structure elements
--
--  More generally, flags is a bitfield with the defined bits:
--    Bit 5-7: See Bit 4
--    Bit 4: Overwrite mathstyle with bit 9-11
--    Bit 3: Generate MathML structure elements
--    Bit 2: Reserved
--    Bit 1: Save MathML as a fully converted formula
--    Bit 0: Save MathML for later usage in startmath node. Ignored for display math.

local mlist_result

local undefined_cmd = token.command_id'undefined_cs'
local call_cmd = token.command_id'call'

local function save_result(xml, display, structelem)
  mlist_result = make_root(xml, display and 0 or 2)
  token.put_next(filename_token)
  local filename = token.scan_argument()
  local tracing = tex.count.tracingmathml > 1
  if filename ~= '' then
    assert(io.open(filename, 'w'))
      :write(write_xml(mlist_result, true):sub(2) .. '\n')
      :close()
  end
  if tracing then
    texio.write_nl(write_xml(mlist_result) .. '\n')
  end
  if tex.count.l__luamml_flag_int & 8 == 8 then
    write_struct(mlist_result)
  end
  return mlist_result
end

luatexbase.add_to_callback('pre_mlist_to_hlist_filter', function(mlist, style)
  if tex.nest.top.mode == mmode then -- This is a equation label generated with \eqno
    return true
  end
  local flag = tex.count.l__luamml_flag_int
  if flag & 3 == 0 then
    return true
  end
  local display = style == 'display'
  local startmath = tex.nest.top.tail -- Must come before any write_struct calls which adds nodes
  style = flag & 4 == 4 and flag>>5 & 0x7 or display and 0 or 2
  local xml, core = process_mlist(mlist, style)
  if flag & 2 == 2 then
    save_result(shallow_copy(xml), display)
  else
    local element_type = token.get_macro'l__luamml_root_tl'
    if element_type ~= 'mrow' then
      if xml[0] == 'mrow' then
        xml[0] = element_type
      else
        xml = {[0] = element_type, xml}
      end
    end
  end
  if not display and flag & 1 == 1 then
    local props = properties[startmath]
    if not props then
      props = {}
      properties[startmath] = props
    end
    props.saved_mathml_table, props.saved_mathml_core = xml, core
    if flag & 10 == 8 then
      write_struct(xml, true) -- This modifies xml in-place to reference the struture element
    end
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
  local mml = write_xml(mlist_result)
  if tex.count.tracingmathml == 1 then
    texio.write_nl(mml .. '\n')
  end
  tex.sprint(-2, tostring(pdf.immediateobj('stream', mml, '/Subtype/application#2Fmathml+xml' .. token.scan_argument(true))))
  mlist_result = nil
end

require'luamml-tex-annotate'

return {
  save_result = save_result,
}
