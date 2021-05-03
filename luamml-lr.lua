local properties = node.get_properties_table()

local function to_unicode(head, tail)
  local result, subresult, i = {[0] = 'mrow'}, {}, 0
  local characters, last_fid
  local iter, state, n = node.traverse(head)
  while true do
    local id, sub n, id, sub = iter(state, n)
    if not n or n == tail then break end
    local props = properties[n]
    if props and props.glyph_info then
      i = i+1
      subresult[i] = glyph_info
    else
      local char, fid = node.is_glyph(n)
      if char then
        if fid ~= last_fid then
          local fontdir = font.getfont(fid)
          characters, last_fid = fontdir.characters, fid
        end
        local uni = characters[char]
        local uni = uni and uni.unicode
        i = i+1
        if uni then
          if type(uni) == 'number' then
            subresult[i] = utf.char(uni)
          else
            subresult[i] = utf.char(table.unpack(uni))
          end
        else
          if char < 0x110000 then
            subresult[i] = utf.char(char)
          else
            subresult[i] = '\u{FFFD}'
          end
        end
      elseif node.id'math' == id then
        if props then
          local mml = props.saved_mathml_table
          if mml then
            if i ~= 0 then
              result[#result+1] = {[0] = 'mtext', table.concat(subresult)}
              for j = i, 1, -1 do subresult[j] = nil end
              i = 0
            end
            result[#result+1] = mml
            n = node.end_of_math(n)
          end
        end
      -- elseif node.id'whatsit' == id then
        -- TODO(?)
      elseif node.id'glue' == id then
        if n.width > 1000 then -- FIXME: Coordinate constant with tagpdf
          i = i+1
          subresult[i] = '\u{00A0}' -- non breaking space... There is no real reason why it has to be non breaking, except that MathML often ignore other spaces
        end
      elseif node.id'hlist' == id then
        local nested = to_unicode(n.head)
        if nested[0] == 'mtext' and #nested == 1 and type(nested[1]) == 'string' then
          i=i+1
          subresult[i] = nested[1]
        else
          if i ~= 0 then
            result[#result+1] = {[0] = 'mtext', table.concat(subresult)}
            for j = i, 1, -1 do subresult[j] = nil end
            i = 0
          end
          if nested[0] == 'mrow' then
            table.move(nested, 1, #nested, #result+1, result)
          else -- should be unreachable (propbably actually is reachable if the inner list only contains math
            result[#result+1] = nested
          end
        end
      elseif node.id'vlist' == id then
        i = i+1
        subresult[i] = '\u{FFFD}'
      elseif node.id'rule' == id then
        if n.width ~= 0 then
          i = i+1
          subresult[i] = '\u{FFFD}'
        end
      end -- CHECK: Everything else can probably be ignored, otherwise shout at me
    end
  end
  if i ~= 0 then
    result[#result+1] = {[0] = 'mtext', table.concat(subresult)}
  end
  if #result == 0 then
    local r = {[0] = 'mtext', ''}
    return r, r
  elseif #result == 1 then
    result = result[1]
    if result[1] == 'mtext' then return result, result end
  end
  return result
end

return to_unicode
