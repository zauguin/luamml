module = "luamml"

tdsroot      = "lualatex"
installfiles = { "luamml-*.lua", "*.sty" }
sourcefiles  = { "luamml-*.lua", "*.sty", "*.dtx" }
stdengine    = "luatex"
checkengines = {"luatex"}
unpackfiles  = { "*.dtx" }
typesetexe   = "lualatex"
