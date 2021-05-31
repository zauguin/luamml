local l = lpeg or require'lpeg'

local line = (1-l.P'\n')^0 * '\n'

local list_block = (l.C(l.S'\\._^/ps' * (1-l.P'\n')^0)^-1 * '\n')^0
local math_lists_block = l.Ct('### ' * l.Cg(l.C'display' * ' ', 'display')^-1 * 'math mode entered at line ' * l.Cg(l.R'09'^1 / tonumber, 'line') * '\n'
                       * list_block)^1
local generic_list_block = '### ' * line * list_block
local luamml_block = l.Ct('LUAMML_META_BEGIN\n\n'
 * (math_lists_block + generic_list_block/0)^0
 * (line - 'LUAMML_META_END\n')^0
 * 'LUAMML_META_END\n')
local log_file = l.Ct((luamml_block + line)^0)

return function(filename)
  local f
  if filename and filename ~= '-' then
    local msg f, msg = assert(io.open(filename, 'r'))
    if not f then return f, msg end
  end
  local content = (f or io.stdin):read'a'
  if f then f:close() end
  -- The following does *not* end with * -1 since we want to allow the last line to not end with \n.
  -- In that case we ignore the last line, but that's safe since the last line never contains our markers.
  return assert(log_file:match(content))
end
