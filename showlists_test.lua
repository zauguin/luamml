require'emulated_nodes'
local convert = require'luamml-convert'
local mappings = require'luamml-legacy-mappings'
local to_xml = require'luamml-xmlwriter'
convert.register_family(1, mappings.oml)
convert.register_family(2, mappings.oms)
convert.register_family(3, mappings.omx)

local parse_showlists = require'parse_showlists'
local l = lpeg or require'lpeg'

local line = (1-l.P'\n')^0 * '\n'
local Cline = l.C((1-l.P'\n')^0) * '\n'

local list_block = (l.C(l.S'\\._^/ps' * (1-l.P'\n')^0)^-1 * '\n')^0
local math_lists_block = l.Ct('### ' * l.Cg(l.C'display' * ' ', 'display')^-1 * 'math mode entered at line ' * l.Cg(l.R'09'^1 / tonumber, 'line') * '\n'
                       * list_block)^1
local generic_list_block = '### ' * line * list_block
local luamml_block = l.Ct('LUAMML_META_BEGIN\n\n'
 * (math_lists_block + generic_list_block/0)^0
 * (line - 'LUAMML_META_END\n')^0
 * 'LUAMML_META_END\n')

local math_lists = (function()
  local f = assert(io.open(arg[1], 'r'))
  local content = f:read'a'
  f:close()
  -- The following does *not* end with * -1 since we want to allow the last line to not end with \n.
  -- In that case we ignore the last line, but that's safe since the last line never contains our markers.
  local log_file = l.Ct((luamml_block + line)^0)
  return log_file:match(content)
end)()
local lines = l.Ct((l.C((1-l.P'\n')^0) * '\n')^0 * l.C(l.P(1)^1)^-1):match(
[[\mathinner
.\left"28300
.\mathord
..\fraction, thickness 0.0, left-delimiter "28300, right-delimiter "29301
..\\mathord
..\.\fam0 1
../\mathord
../.\fam0 1
.\mathord
..\fam1 x
._\mathord
._.\fam0 1
._\mathord
._.\fam1 =
._\mathord
._.\fam0 2
.\mathchoice
.D\mathord
.D.\fam1 d
.D\mathord
.D.\fam1 i
.D\mathord
.D.\fam1 s
.D\mathord
.D.\fam1 p
.D\mathord
.D.\fam1 l
.D\mathord
.D.\fam1 a
.D\mathord
.D.\fam1 y
.D\scriptstyle
.D\mathord
.D.\fam1 a
.D\mathord
.D.\fam1 b
.D\mathord
.D.\fam1 c
.T\mathord
.T.\fam1 t
.T\mathord
.T.\fam1 e
.T\mathord
.T.\fam1 x
.T\mathord
.T.\fam1 t
.T\scriptscriptstyle
.T\mathord
.T.\fam1 a
.T\mathord
.T.\fam1 b
.T\mathord
.T.\fam1 c
.S\mathord
.S.\fam1 s
.S\mathord
.S.\fam1 c
.S\mathord
.S.\fam1 r
.S\mathord
.S.\fam1 i
.S\mathord
.S.\fam1 p
.S\mathord
.S.\fam1 t
.S\textstyle
.S\mathord
.S.\fam1 a
.S\mathord
.S.\fam1 b
.S\mathord
.S.\fam1 c
.s\mathord
.s.\fam1 s
.s\mathord
.s.\fam1 c
.s\mathord
.s.\fam1 r
.s\mathord
.s.\fam1 i
.s\mathord
.s.\fam1 p
.s\mathord
.s.\fam1 t
.s\mathord
.s.\fam1 s
.s\mathord
.s.\fam1 c
.s\mathord
.s.\fam1 r
.s\mathord
.s.\fam1 i
.s\mathord
.s.\fam1 p
.s\mathord
.s.\fam1 t
.s\displaystyle
.s\mathord
.s.\fam1 a
.s\mathord
.s.\fam1 b
.s\mathord
.s.\fam1 c
.\mathbin
..\fam0 +
.\accent\fam0 _
..\fam1 z
._\fam0 0
.\right"29301
\mathrel
.\fam0 =
\mathop\nolimits
.\fam3 P
^\fam0 1
_\mathord
_.\fam1 i
_\mathrel
_.\fam0 =
_\mathord
_.\fam0 1
\mathord
.\fraction, thickness = default
.\\mathbin
.\.\fam2 ^^@
.\\mathord
.\.\fam1 p
.\\mathbin
.\.\fam2 ^^F
.\\radical"270370
.\.\mathord
.\..\fam1 p
.\.\mathbin
.\..\fam2 ^^@
.\.\mathord
.\..\fam0 4
.\.\mathord
.\..\fam1 q
./\mathord
./.\fam0 2
]])

for i, block in ipairs(math_lists) do
  block = block[1]
  local parsed = parse_showlists(block)
  local style = block.display and 0 or 2
  print(to_xml(convert.make_root(convert.process(parsed, style), style)))
end
