module = "luamml"

tdsroot      = "lualatex"
installfiles = { "luamml-*.lua", "*.sty" }
sourcefiles  = { "luamml-*.lua", "*.sty", "*.dtx" }
stdengine    = "luatex"
unpackfiles  = { "*.dtx" }
typesetexe   = "lualatex"

checkconfigs = {
  'config-lua',
  'config-pdf',
}
