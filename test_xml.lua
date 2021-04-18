local write_xml = require'write_xml'

print(write_xml{[0] = "math", xmlns = "http://www.w3.org/1998/Math/MathML",
    {[0] = "mi", "a"},
    {[0] = "msup",
      {[0] = "mi", "x"},
      {[0] = "mn", "2"},
    },
    {[0] = "mo", "+"},
    {[0] = "mi", "b"},
    {[0] = "mi", "x"},
    {[0] = "mo", "+"},
    {[0] = "mi", "c"},
    {[0] = "mo", "="},
    {[0] = "mn", "0"},
  })
