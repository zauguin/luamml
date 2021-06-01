#!/usr/bin/env texlua
require'pdfmml-emulate-node'
local convert = require'luamml-convert'
local mappings = require'luamml-legacy-mappings'
local to_xml = require'luamml-xmlwriter'
convert.register_family(1, mappings.oml)
convert.register_family(2, mappings.oms)
convert.register_family(3, mappings.omx)

local parse_showlists = require'pdfmml-showlists'
local parse_log = require'pdfmml-logreader'

if #arg < 1 then
  io.stderr:write(string.format('Usage: %0 {logname} \n', arg[0]))
  os.exit(1)
end
local math_lists = assert(parse_log(arg[1]))

local out_stream = arg[2] and arg[2] ~= '-' and assert(io.open(arg[2], 'w')) or io.stdout
for i, block in ipairs(math_lists.groups) do
  block = block[1]
  local parsed = parse_showlists(block, nil, nil, math_lists.marks)
  local style = block.display and 0 or 2
  out_stream:write(
    to_xml(convert.make_root(convert.process(parsed, style), style))
  )
end
-- if ... then out_stream:close() end -- Don't bother since we terminate anyway
