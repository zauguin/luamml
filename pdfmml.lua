#!/usr/bin/env texlua
require'pdfmml-emulate-node'
local convert = require'luamml-convert'
local mappings = require'luamml-legacy-mappings'
local to_xml = require'luamml-xmlwriter'

local parse_showlists = require'pdfmml-showlists'
local parse_log = require'pdfmml-logreader'

local attributes = lfs.attributes
local function try_extensions_(base, extension, ...)
  if extension == nil then return end
  local fullname = base .. extension
  if attributes(fullname, 'mode') == 'file' then
    return fullname
  end
  return try_extensions_(base, ...)
end
local function try_extensions(base, ...)
  if attributes(base, 'mode') == 'file' then return base end
  return try_extensions_(base, ...)
end

if #arg < 1 then
  io.stderr:write(string.format('Usage: %s {logname} [{outname}]\n\z
    If {outname} includes {}, then a separate file is written for every formula with {} replaced by the formula id.\n', arg[0]))
  os.exit(1)
end
local parsed = assert(parse_log(assert(try_extensions(arg[1], '.tml', '.log'),
      "Couldn't find input file.")))

for i, inst in ipairs(parsed.instructions) do
  local _, _, family, mapping_name = inst:find'^REGISTER_MAPPING:([0-9]+):(.*)$'
  if family then
    local mapping = mappings[mapping_name]
    if mapping then
      convert.register_family(tonumber(family), mapping)
    else
      io.stderr:write(string.format('Unknown mapping %s ignored\n', mapping_name))
    end
  else
    io.stderr:write'Unknown instruction ignored\n'
  end
end

local out_prefix, out_suffix, out_stream
if not arg[2] or arg[2] == '-' then
  out_stream = io.stdout
else
  local _ _, _, out_prefix, out_suffix = arg[2]:find'^(.*){}(.*)$'
  if not out_prefix then
    out_stream = assert(io.open(arg[2], 'w'))
  end
end
for i, block in ipairs(parsed.groups) do
  local stream = out_stream or assert(io.open(out_prefix .. tostring(i) .. out_suffix, 'w'))
  block = block[1]
  local parsed = parse_showlists(block, nil, nil, parsed.marks)
  local style = block.display and 0 or 2
  stream:write(
    to_xml(convert.make_root(convert.process(parsed, style), style)), '\n'
  )
  if not out_stream then stream:close() end
end
