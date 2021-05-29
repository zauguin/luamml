local parse_showlists = require'parse_showlists'
local l = lpeg or require'lpeg'

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
.\mathbin
..\fam0 +
.\accent\fam0 _
..\fam1 z
._\fam0 0
.\middle"26A30C
.\mathrel
..\fam0 =
.\mathop\limits
..\fam3 P
.\mathop\nolimits
..\fam3 P
.\mathop
..\fam3 P
.^\mathord
.^.\fam0 1
.^\mathord
.^.\fam0 0
.^\mathord
.^.\fam0 0
.^\mathord
.^.\fam0 0
._\mathord
._.\fam1 i
._\mathrel
._.\fam0 =
._\mathord
._.\fam0 1
.\mathord
..\fraction, thickness = default
..\\mathbin
..\.\fam2 ^^@
..\\mathord
..\.\fam1 p
..\\mathbin
..\.\fam2 ^^F
..\\radical"270370
..\.\mathord
..\..\fam1 p
..\.\mathbin
..\..\fam2 ^^@
..\.\mathord
..\..\fam0 4
..\.\mathord
..\..\fam1 q
../\mathord
../.\fam0 2
.\right"0
]])

local parsed = parse_showlists(lines)
require'emulated_nodes'
local convert = require'luamml-convert'
local mappings = require'luamml-legacy-mappings'
convert.register_family(1, mappings.oml)
convert.register_family(2, mappings.oms)
convert.register_family(3, mappings.omx)
local to_xml = require'luamml-xmlwriter'
print(to_xml(convert.make_root(convert.process(parsed), 2)))
