module = "luamml"

tdsroot      = "lualatex"
installfiles = { "luamml-*.lua", "*.sty" }
sourcefiles  = { "luamml-*.lua", "*.sty", "*.dtx" }
typesetsuppfiles = { "*.tex" }
typesetsourcefiles = { "*.tex" }
stdengine    = "luatex"
unpackfiles  = { "*.dtx" }
typesetexe   = "lualatex"

checkconfigs = {
  'config-lua',
  'config-pdf',
}
