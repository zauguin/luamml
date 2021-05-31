local l = lpeg or require'lpeg'
local hex_digit = l.R('09', 'af')
local function hex_to_int(s) return tonumber(s, 16) end
local tex_char = l.Cg('^^' * (hex_digit * hex_digit / hex_to_int
                           + l.R'\0\x3F' / function(s) return s:byte() + 0x40  end
                           + l.R'\x40\x7F' / function(s) return s:byte() - 0x40  end)
                   + l.P(1) / string.byte)

local scaled = l.R'09'^1 * '.' * l.R'09'^1 / function(s) return (tonumber(s * 0x10000) + .5) // 1 end
local delimiter_code = '"' * (l.R('09', 'AF')^1 / function(s)
  local code = tonumber(s, 16)
  return {id = 'delim',
    small_fam = (code >> 20) & 0xF,
    small_char = (code >> 12) & 0xFF,
    large_fam = (code >> 8) & 0xF,
    large_char = code & 0xFF,
  }
end)

local math_char = l.Ct('\\fam' * l.Cg(l.R'09'^1 / tonumber, 'fam') * ' ' * l.Cg(tex_char, 'char') * l.Cg(l.Cc'math_char', 'id'))

local simple_noad = l.Ct(
    '\\math' * l.Cg(
        'ord' * l.Cc(0)
      + 'op\\limits' * l.Cc(2)
      + 'op\\nolimits' * l.Cc(3)
      + 'op' * l.Cc(1)
      + 'bin' * l.Cc(4)
      + 'rel' * l.Cc(5)
      + 'open' * l.Cc(6)
      + 'close' * l.Cc(7)
      + 'punct' * l.Cc(8)
      + 'inner' * l.Cc(9)
      + 'under' * l.Cc(10)
      + 'over' * l.Cc(11)
      + 'vcenter' * l.Cc(12)
      , 'subtype') * l.Cg(l.Cc'noad', 'id')
  + '\\radical' * l.Cg(delimiter_code, 'left') * l.Cg(l.Cc(0), 'subtype') * l.Cg(l.Cc'radical', 'id')
  + '\\accent' * l.Cg(math_char, 'accent') * l.Cg(l.Cc(0), 'subtype') * l.Cg(l.Cc'accent', 'id')
  + l.Cg('\\left' * l.Cc(1)
       + '\\middle' * l.Cc(2)
       + '\\right' * l.Cc(3), 'subtype') * l.Cg(delimiter_code, 'delim')
           * l.Cg(l.Cc(0), 'options') * l.Cg(l.Cc(0), 'height')
           * l.Cg(l.Cc(0), 'depth') * l.Cg(l.Cc(0), 'height')
           * l.Cg(l.Cc(-1), 'class') * l.Cg(l.Cc'fence', 'id')
  + '\\' * l.Cg(
      'display' * l.Cc(0)
    + 'text' * l.Cc(2)
    + 'scriptscript' * l.Cc(6)
    + 'script' * l.Cc(4), 'subtype') * l.Cg('style', 'id')
  ) * -1

local fraction_noad = l.Ct('\\fraction, thickness '
                    * l.Cg('= default' * l.Cc(0x40000000) + scaled, 'width')
                    * l.Cg(', left-delimiter ' * delimiter_code, 'left')^-1 * l.Cg(', right-delimiter ' * delimiter_code, 'right')^-1
                    * l.Cg(l.Cc'fraction', 'id'))
                    * -1

local mathchoice_noad = l.Ct('\\mathchoice' * l.Cg(l.Cc'choice', 'id') * -1)

local parse_list
local function parse_kernel(lines, i, prefix)
  local line = lines[i]
  if not line or line:sub(1, #prefix) ~= prefix then return nil, i end
  local result = math_char:match(lines[i], #prefix + 1)
  if result then return result, i+1 end
  result, i = parse_list(lines, i, prefix)
  return {list = result, id = 'sub_mlist'}, i
end
function parse_list(lines, i, prefix)
  i = i or 1
  prefix = prefix or ''
  local head, last
  while true do
    local line = lines[i]
    if not line or line:sub(1, #prefix) ~= prefix then break end
    local simple = simple_noad:match(line, #prefix+1)
    if simple then
      simple.nucleus, i = parse_kernel(lines, i + 1, prefix .. '.')
      simple.sup, i = parse_kernel(lines, i, prefix .. '^')
      simple.sub, i = parse_kernel(lines, i, prefix .. '_')
      if last then
        simple.prev, last.next = last, simple
      end
      last = simple
    else
      local fraction = fraction_noad:match(line, #prefix+1)
      if fraction then
        fraction.num, i = parse_kernel(lines, i + 1, prefix .. '\\')
        fraction.denom, i = parse_kernel(lines, i, prefix .. '/')
        if last then
          fraction.prev, last.next = last, fraction
        end
        last = fraction
      else
        local mathchoice = mathchoice_noad:match(line, #prefix+1)
        if mathchoice then
          mathchoice.display, i = parse_list(lines, i + 1, prefix .. 'D')
          mathchoice.text, i = parse_list(lines, i, prefix .. 'T')
          mathchoice.script, i = parse_list(lines, i, prefix .. 'S')
          mathchoice.scriptscript, i = parse_list(lines, i, prefix .. 's')
          if last then
            mathchoice.prev, last.next = last, mathchoice
          end
          last = mathchoice
        else
          print(line, prefix, i)
          print('unknown noad ' .. line:sub(#prefix+1))
          i = i + 1
        end
      end
    end
    if not head then head = last end
  end
  return head, i
end
return parse_list
