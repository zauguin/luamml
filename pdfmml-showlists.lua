require'pdfmml-emulate-node'

local properties = node.get_properties_table()

local l = lpeg or require'lpeg'
local hex_digit = l.R('09', 'af')
local function hex_to_int(s) return tonumber(s, 16) end
local tex_char = l.Cg('^^' * (hex_digit * hex_digit / hex_to_int
                           + l.R'\0\x3F' / function(s) return s:byte() + 0x40  end
                           + l.R'\x40\x7F' / function(s) return s:byte() - 0x40  end)
                   + l.P(1) / string.byte)

local scaled = l.P'-'^-1 * l.R'09'^1 * '.' * l.R'09'^1 / function(s) return (tonumber(s * 0x10000) + .5) // 1 end
local int = l.P'-'^-1 * l.R'09'^1 / tonumber
local glue_order_mu = 'filll' * l.Cc(3)
                    + 'fill' * l.Cc(2)
                    + 'fil' * l.Cc(1)
                    + 'mu' * l.Cc(0)
local glue_order_pt = 'filll' * l.Cc(3)
                    + 'fill' * l.Cc(2)
                    + 'fil' * l.Cc(1)
                    + 'pt' * l.Cc(0)
local glue_order = 'filll' * l.Cc(3)
                 + 'fill' * l.Cc(2)
                 + 'fil' * l.Cc(1)
                 + l.Cc(0)
local delimiter_code = '"' * (l.R('09', 'AF')^1 / function(s)
  local code = tonumber(s, 16)
  return {id = 'delim',
    small_fam = (code >> 20) & 0xF,
    small_char = (code >> 12) & 0xFF,
    large_fam = (code >> 8) & 0xF,
    large_char = code & 0xFF,
  }
end)

local balanced_braces = l.Ct{'{' * (1-l.S'{}'+l.V(1))^0 * '}'}

local math_char = l.Ct('\\fam' * l.Cg(l.R'09'^1 / tonumber, 'fam') * ' ' * l.Cg(tex_char, 'char') * l.Cg(l.Cc'math_char', 'id'))

local hdw = '(' * l.Cg(scaled + '*' * l.Cc(-0x40000000), 'height') * '+' * l.Cg(scaled + '*' * l.Cc(-0x40000000), 'depth') * ')x' * l.Cg(scaled + '*' * l.Cc(-0x40000000), 'width')

local generic_simple_node = l.Ct(
  '\\' * l.Cg('rule', 'id') * hdw
  + '\\kern' * l.Cg(' ' * l.Cc(1) + l.Cc(0), 'subtype') * l.Cg(scaled, 'kern') * (' (for ' * (l.R'az' + l.S'/\\') * ')')^-1 * l.Cg(l.Cc'kern', 'id')
  + '\\glue' * l.Cg('(\\' * (
        'line' * l.Cc(1)
      + 'baseline' * l.Cc(2)
      + 'par' * l.Cc(3)
      + 'abovedisplay' * l.Cc(4)
      + 'belowdisplay' * l.Cc(5)
      + 'abovedisplayshort' * l.Cc(6)
      + 'belowdisplayshort' * l.Cc(7)
      + 'left' * l.Cc(8)
      + 'right' * l.Cc(9)
      + 'top' * l.Cc(10)
      + 'splittop' * l.Cc(11)
      + 'tab' * l.Cc(12)
      + 'space' * l.Cc(13)
      + 'xspace' * l.Cc(14)
      + 'parfill' * l.Cc(15)
      + 'math' * l.Cc(16)
      + 'thinmu' * l.Cc(17)
      + 'medmu' * l.Cc(18)
      + 'thickmu' * l.Cc(19)) * 'skip)' + l.Cc(0), 'subtype')
    * ' ' * l.Cg(scaled, 'width')
    * (' plus ' * l.Cg(scaled, 'stretch') * l.Cg(glue_order, 'stretch_order') + l.Cg(l.Cc(0), 'stretch') * l.Cg(l.Cc(0), 'stretch_order'))
    * (' minus ' * l.Cg(scaled, 'shrink') * l.Cg(glue_order, 'shrink_order') + l.Cg(l.Cc(0), 'shrink') * l.Cg(l.Cc(0), 'shrink_order'))
    * l.Cg(l.Cc'glue', 'id')
  + '\\penalty ' * l.Cg(int, 'penalty') * l.Cg(l.Cc'penalty', 'id')
  + '\\mark' * l.Cg('s' * int + l.Cc(0), 'class') * l.Cg(balanced_braces, 'mark') * l.Cg(l.Cc'mark', 'id')
) * -1

local simple_noad = l.Ct(
    '\\math' * l.Cg(
        'ord' * l.Cc(0)
      + 'open' * l.Cc(6)
      + 'op\\limits' * l.Cc(2)
      + 'op\\nolimits' * l.Cc(3)
      + 'op' * l.Cc(1)
      + 'bin' * l.Cc(4)
      + 'rel' * l.Cc(5)
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
  + '\\glue(\\nonscript)' * l.Cg(l.Cc(98), 'subtype') * l.Cg(l.Cc'glue', 'id')
  + '\\mkern' * l.Cg(scaled, 'kern') * 'mu' * l.Cg(l.Cc(99), 'subtype') * l.Cg(l.Cc'kern', 'id')
  + '\\glue(\\mskip)' * l.Cg(l.Cc(99), 'subtype')
    * ' ' * l.Cg(scaled, 'width') * 'mu'
    * (' plus ' * l.Cg(scaled, 'stretch') * l.Cg(glue_order_mu, 'stretch_order') + l.Cg(l.Cc(0), 'stretch') * l.Cg(l.Cc(0), 'stretch_order'))
    * (' minus ' * l.Cg(scaled, 'shrink') * l.Cg(glue_order_mu, 'shrink_order') + l.Cg(l.Cc(0), 'shrink') * l.Cg(l.Cc(0), 'shrink_order'))
    * l.Cg(l.Cc'glue', 'id')
  ) * -1
+ generic_simple_node

local simple_text = l.Ct(
    '\\math' * l.Cg(
        'on' * l.Cc(0)
      + 'off' * l.Cc(6)
      , 'subtype') * l.Cg(', surrounded ' * scaled + l.Cc(0), 'surround') * l.Cg(l.Cc'math', 'id')
  ) * -1
+ generic_simple_node

local box_node = l.Ct('\\' * l.Cg('h' * l.Cc'hlist'
                                + 'v' * l.Cc'vlist') * 'box'
                              * hdw
                              * (', glue set ' * l.Cg('- ' * l.Cc(2) + l.Cc(1), 'glue_sign')
                                 * l.Cg(scaled/function (s) return s/65536 end, 'glue_set')
                                 * l.Cg(glue_order, 'glue_order')
                                 + l.Cg(l.Cc(0), 'glue_sign') * l.Cg(l.Cc(0), 'glue_set') * l.Cg(l.Cc(0), 'glue_order'))
                              * l.Cg(', shifted ' * scaled + l.Cc(0), 'shift')) * -1

local fraction_noad = l.Ct('\\fraction, thickness '
                    * l.Cg('= default' * l.Cc(0x40000000) + scaled, 'width')
                    * l.Cg(', left-delimiter ' * delimiter_code, 'left')^-1 * l.Cg(', right-delimiter ' * delimiter_code, 'right')^-1
                    * l.Cg(l.Cc'fraction', 'id'))
                    * -1

local mathchoice_noad = l.Ct('\\mathchoice' * l.Cg(l.Cc'choice', 'id') * -1)

local mark_whatsit = '\\write' * ('-' + l.R'09'^1) * '{LUAMML_MARK_REF:' * (l.R'09'^1/tonumber) * ':'

local parse_list
local function parse_kernel(lines, i, prefix, parsed)
  local line = lines[i]
  if not line or line:sub(1, #prefix) ~= prefix then return nil, i end
  local result = math_char:match(lines[i], #prefix + 1)
  if result then return result, i+1 end
  if box_node:match(lines[i], #prefix + 1) then return skip_list(lines, i+1, prefix .. '.') end
  result, i = parse_list(lines, i, prefix, parsed)
  return {list = result, id = 'sub_mlist'}, i
end
function skip_list(lines, i, prefix)
  i = i or 1
  local count = #lines
  while i <= count and lines[i]:sub(1, #prefix) == prefix do
    i = i + 1
  end
  return {id = 'sub_box', list = {}}, i
end
function parse_list(lines, i, prefix, parsed)
  i = i or 1
  prefix = prefix or ''
  local head, last
  local mark_environment = {data = parsed,}
  local current_mark, current_count, current_offset
  while true do
    local skip
    local line = lines[i]
    if not line or line:sub(1, #prefix) ~= prefix then break end
    local simple = simple_noad:match(line, #prefix+1)
    if simple then
      simple.nucleus, i = parse_kernel(lines, i + 1, prefix .. '.', parsed)
      simple.sup, i = parse_kernel(lines, i, prefix .. '^', parsed)
      simple.sub, i = parse_kernel(lines, i, prefix .. '_', parsed)
      if last then
        simple.prev, last.next = last, simple
      end
      last = simple
    else
      local fraction = fraction_noad:match(line, #prefix+1)
      if fraction then
        fraction.num, i = parse_kernel(lines, i + 1, prefix .. '\\', parsed)
        fraction.denom, i = parse_kernel(lines, i, prefix .. '/', parsed)
        if last then
          fraction.prev, last.next = last, fraction
        end
        last = fraction
      else
        local mathchoice = mathchoice_noad:match(line, #prefix+1)
        if mathchoice then
          mathchoice.display, i = parse_list(lines, i + 1, prefix .. 'D', parsed)
          mathchoice.text, i = parse_list(lines, i, prefix .. 'T', parsed)
          mathchoice.script, i = parse_list(lines, i, prefix .. 'S', parsed)
          mathchoice.scriptscript, i = parse_list(lines, i, prefix .. 's', parsed)
          if last then
            mathchoice.prev, last.next = last, mathchoice
          end
          last = mathchoice
        else
          skip = true
          local mark = mark_whatsit:match(line, #prefix+1)
          if mark then
            local mark_table = assert(load('return {' .. assert(parsed.marks[mark], 'Undefined mark encountered') .. '}', nil, 't', mark_environment))()
            if current_mark then
              if (mark_table.count or 1) > current_count then
                error'Invalid mark nesting'
              end
              -- Ignore new mark if existing mark is evaluated. This should be replaced with proper nesting
            else
              current_mark, current_count = mark_table, mark_table.count or 1
              current_offset = mark_table.offset or current_count
            end
            i = i + 1
          else
            print(line, prefix, i)
            print('unknown noad ' .. line:sub(#prefix+1))
            i = i + 1
          end
        end
      end
    end
    if not head then head = last end
    if not skip and current_mark then
      current_count = current_count - 1
      current_offset = current_offset - 1
      if current_offset == 0 then
        properties[current_mark.nucleus and last.nucleus or last] = {mathml_core = current_mark.core}
      else
        properties[last] = {mathml_core = false}
      end
      if current_count == 0 then current_mark = nil end
    end
  end
  return head, i
end
return parse_list
