testfiledir  = "testfiles-lua"
checkengines = {"luatex"}
stdengine     = "luatex"
checkruns    = 3

test_types = test_types or {}
test_types.mml = {
  test = '.mlt',
  generated = '.mml',
  reference = '.mlr',
  expectation = '.mle',
  rewrite = function(source, result, engine, errlevels)
    return os.execute(string.format('tidy -xml -indent -wrap -quiet --output-file "%s" "%s"', result, source))
  end,
}

test_order = {'log', 'pdf', 'mml'}
