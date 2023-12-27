#!/usr/bin/env texlua
require'pdfmml-emulate-node'
local convert = require'luamml-convert'
local mappings = require'luamml-legacy-mappings'
local to_xml = require'luamml-xmlwriter'

local parse_showlists = require'pdfmml-showlists'
local parse_log = require'pdfmml-logreader'

local text_families = {}

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
parsed.mathml = {}

local function shallow_copy(t)
  local new = {}
  for k, v in next, t do
    new[k] = v
  end
  return new
end

-- Currently only 3 flag values are supported:
--   0: Ignore (Doesn't make a lot of sense here)
--   1: Only save
--   3: Generate normally
for i, block in ipairs(parsed.groups) do
  local flag, tag, label = block.flag, block.tag, block.label
  block = block[1]
  if flag & 3 ~= 0 then
    local style = flag & 16 == 16 and flag>>5 & 0x7 or block.display and 0 or 2
    local xml = convert.process(parse_showlists(block, nil, nil, parsed), style, text_families)
    if flag & 2 == 2 then
      local stream = out_stream or assert(io.open(out_prefix .. tostring(i) .. out_suffix, 'w'))
      stream:write(to_xml(convert.make_root(shallow_copy(xml), style)), '\n')
      if not out_stream then stream:close() end
    end
    if tag ~= 'mrow' then
      if xml[0] == 'mrow' then
        xml[0] = tag
      else
        xml = {[0] = tag, xml}
      end
    end
    if (not block.display) and flag & 1 == 1 and label then
      if parsed.mathml[label] then
        error'Invalid label reuse'
      end
      parsed.mathml[label] = xml
    end
  end
end
