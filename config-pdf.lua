testfiledir  = "testfiles-pdf"
checkengines = {"pdftex"}
stdengine     = "pdftex"
checkruns    = 3

test_types = test_types or {}
test_types.tml = {
  test = '.xrt',
  generated = '.tml',
  reference = '.txr',
  expectation = '.xre',
  rewrite = function(source, result, engine, errlevels)
    local file = assert(io.open(source,"rb"))
    local content = string.gsub(file:read("*all") .. "\n","\r\n","\n")
    file:close()
    local new_content = content
    -- local new_content = processor(content,...)
    local newfile = io.open(result,"w")
    newfile:write(new_content)
    newfile:close()
  end,
}
test_types.mml = {
  test = '.mlt',
  generated = '.tml',
  reference = '.mlr',
  expectation = '.mle',
  rewrite = function(source, result, engine, errlevels)
    return os.execute(string.format('texlua pdfmml.lua "%s" | tidy -xml -indent -wrap -quiet --output-file "%s" -', source, result))
  end,
}

test_order = {'log', 'pdf', 'tml', 'mml'}
