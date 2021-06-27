local l = lpeg or require'lpeg'

local line = (1-l.P'\n')^0 * '\n'

local id = l.R'09'^1/tonumber
local non_final_list_block = (l.C((1-l.P'\n')^1) * '\n' - '### ' + '\n')^0
local math_lists_block = l.Ct('### ' * l.Cg(l.C'display' * ' ', 'display')^-1 * 'math mode entered at line ' * l.Cg(l.R'09'^1 / tonumber, 'line') * '\n'
                       * non_final_list_block)^1
local generic_list_block = '### ' * (line - 'current page:') * non_final_list_block
local luamml_block = l.Cg('LUAMML_FORMULA_BEGIN:' * id * ':' * l.Ct(
   l.Cg(id, 'flag') * ':' * l.Cg((1-l.S':\n')^0, 'tag') * ':' * l.Cg((1-l.P'\n')^1, 'label')^-1 * l.P'\n'^1
   
 * (math_lists_block + generic_list_block/0)^0
 * (line - 'LUAMML_FORMULA_END\n')^0
 * 'LUAMML_FORMULA_END\n') * l.Cc'groups')

local luamml_mark = l.Cg('LUAMML_MARK:' * id * ':' * l.Cs((1 - l.P'\n' + l.Cg('\n' * l.Cc'' - '\nLUAMML_MARK_END\n'))^0) * '\nLUAMML_MARK_END\n' * l.Cc'marks')

local function add(a, b) return a + b end
local count_block = '### ' * line * l.Cf(l.Cc(0) * (('\\' * l.Cc(1))^-1 * line - '### ')^0, add)
local luamml_count = l.Cg('LUAMML_COUNT:' * id * l.P'\n'^1
                      * count_block
                      * (line-'LUAMML_COUNT_END\n')^0
                      * 'LUAMML_COUNT_END' * l.P'\n'^1
                      * count_block / function(id, first, second)
                        return id, second - first
                      end * l.Cc'count')

local luamml_instruction = l.Cg('LUAMML_INSTRUCTION:' * l.Cc(nil) * l.C((1 - l.P'\n')^0) * '\n' * l.Cc'instructions')

local function multi_table_set(t, key, value, table)
  table = t[table]
  table[key or #table + 1] = value
  return t
end
local log_file = l.Cf(l.Ct(l.Cg(l.Ct'', 'groups')
                    * l.Cg(l.Ct'', 'count')
                    * l.Cg(l.Ct'', 'marks')
                    * l.Cg(l.Ct'', 'instructions'))
               * (luamml_block + luamml_mark + luamml_instruction + luamml_count + line)^0,
               multi_table_set)

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
