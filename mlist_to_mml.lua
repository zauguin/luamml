local remap_comb = require'remap_comb'
local stretchy = require'stretchy'

local properties = node.get_properties_table()

local kern_t, glue_t = node.id'kern', node.id'glue'

local noad_t, accent_t, style_t, choice_t = node.id'noad', node.id'accent', node.id'style', node.id'choice'
local radical_t, fraction_t, fence_t = node.id'radical', node.id'fraction', node.id'fence'

local math_char_t, sub_box_t, sub_mlist_t = node.id'math_char', node.id'sub_box', node.id'sub_mlist'

local noad_sub = node.subtypes'noad'
local radical_sub = node.subtypes'radical'
local fence_sub = node.subtypes'fence'

local remap_lookup = setmetatable({}, {__index = function(t, k)
  local ch = utf8.char(k & 0x1FFFFF)
  t[k] = ch
  return ch
end})
local digit_map = {["0"] = true, ["1"] = true,
     ["2"] = true, ["3"] = true, ["4"] = true,
     ["5"] = true, ["6"] = true, ["7"] = true,
     ["8"] = true, ["9"] = true,}

local nodes_to_table

local function sub_style(s) return s//4*2+5 end
local function sup_style(s) return s//4*2+4+s%2 end

-- We ignore large_... since they aren't used for modern fonts
local function delim_to_table(delim)
  if not delim then return end
  local props = properties[delim] props = props and props.mathml_table
  if props then return props end
  local fam = delim.small_fam
  local char = remap_lookup[fam << 21 | delim.small_char]
  return {[0] = 'mo', char, ['tex:family'] = fam ~= 0 and fam or nil, stretchy = not stretchy[char] or nil }
end

-- Like kernel_to_table but always a math_char_t. Also creating a mo and potentially remapping to handle combining chars
local function acc_to_table(acc, cur_style, stretch)
  if not acc then return end
  local props = properties[acc] props = props and props.mathml_table
  if props then return props end
  if acc.id ~= math_char_t then
    error'confusion'
  end
  local fam = acc.fam
  local char = remap_lookup[fam << 21 | acc.char]
  char = remap_comb[char] or char
  if stretch ~= not stretchy[char] then -- Handle nil gracefully in stretchy
    stretch = nil
  end
  return {[0] = 'mo', char, ['tex:family'] = fam ~= 0 and fam or nil, stretchy = stretch}
end

local function kernel_to_table(kernel, cur_style)
  if not kernel then return end
  local props = properties[kernel] props = props and props.mathml_table
  if props then return props end
  local id = kernel.id
  if id == math_char_t then
    local fam = kernel.fam
    local char = remap_lookup[fam << 21 | kernel.char]
    local elem = digit_map[char] and 'mn' or 'mi'
    return {[0] = elem,
      char,
      ['tex:family'] = fam ~= 0 and fam or nil,
      mathvariant = #char == 1 and utf8.codepoint(char) < 0x10000 and 'normal' or nil
    }
  elseif id == sub_box_t then
    return {[0] = 'mi', {[0] = 'mglyph', ['tex:box'] = kernel.list}}
  elseif id == sub_mlist_t then
    return nodes_to_table(kernel.list, cur_style)
  else
    error'confusion'
  end
end

local function do_sub_sup(t, n, cur_style)
  local sub = kernel_to_table(n.sub, sub_style(cur_style))
  local sup = kernel_to_table(n.sup, sup_style(cur_style))
  if sub then
    if sup then
      return {[0] = 'msubsup', t, sub, sup}
    else
      return {[0] = 'msub', t, sub}
    end
  elseif sup then
    return {[0] = 'msup', t, sup}
  else
    return t
  end
end

local function noad_to_table(noad, sub, cur_style)
  local class = noad_sub[sub]
  local nucleus = kernel_to_table(noad.nucleus, class == 'over' and cur_style//2*2+1 or cur_style)
  if class == 'ord' then
  elseif class == 'opdisplaylimits' or class == 'oplimits' or class == 'opnolimits' or class == 'bin' or class == 'rel' or class == 'open'
      or class == 'close' or class == 'punct' or class == 'inner' then
    if nucleus[0] == 'mrow' then
      -- TODO
    else
      nucleus[0] = 'mo'
      if stretchy[nucleus[1]] then nucleus.stretchy = false end
      if nucleus.mathvariant == 'normal' then nucleus.mathvariant = nil end
    end
    nucleus['tex:class'] = class

    if (noad.sup or noad.sub) and (class == 'opdisplaylimits' or class == 'oplimits') then
      nucleus.movablelimits = class == 'opdisplaylimits'
      local sub = kernel_to_table(noad.sub, sub_style(cur_style))
      local sup = kernel_to_table(noad.sup, sup_style(cur_style))
      return {[0] = sup and (sub and 'munderover' or 'mover') or 'munder',
        nucleus,
        sub or sup,
        sub and sup,
      }
    end
  elseif class == 'under' then
    return {[0] = 'munder',
      nucleus,
      {[0] = 'mo', '_',},
    }
  elseif class == 'over' then
    return {[0] = 'mover',
      nucleus,
      {[0] = 'mo', '\u{203E}',},
    }
  elseif class == 'vcenter' then
    nucleus['tex:TODO'] = class
  else
    error[[confusion]]
  end
  return do_sub_sup(nucleus, noad, cur_style)
end

local function accent_to_table(accent, sub, cur_style)
  local nucleus = kernel_to_table(accent.nucleus, cur_style//2*2+1)
  local top_acc = acc_to_table(accent.accent, cur_style, sub & 1 == 1)
  local bot_acc = acc_to_table(accent.bot_accent, cur_style, sub & 2 == 2)
  return {[0] = top_acc and (bot_acc and 'munderover' or 'mover') or 'munder',
    nucleus,
    bot_acc or top_acc,
    bot_acc and top_acc,
  }
end

local style_table = {
  display = {displaystyle = "true", scriptlevel = "0"},
  text = {displaystyle = "false", scriptlevel = "0"},
  script = {displaystyle = "false", scriptlevel = "1"},
  scriptscript = {displaystyle = "false", scriptlevel = "2"},
}

style_table.crampeddisplay, style_table.crampedtext,
style_table.crampedscript, style_table.crampedscriptscript = 
  style_table.display, style_table.text,
  style_table.script, style_table.scriptscript

local function radical_to_table(radical, sub, cur_style)
  local kind = radical_sub[sub]
  local nucleus = kernel_to_table(radical.nucleus, cur_style//2*2+1)
  local left = delim_to_table(radical.left)
  local elem
  if kind == 'radical' or kind == 'uradical' then
    -- FIXME: Check that this is really a square root
    elem = {[0] = 'msqrt', nucleus}
  elseif kind == 'uroot' then
    -- FIXME: Check that this is really a root
    elem = {[0] = 'msqrt', nucleus, kernel_to_table(radical.degree)}
  elseif kind == 'uunderdelimiter' then
    elem = {[0] = 'munder', left, nucleus}
  elseif kind == 'uoverdelimiter' then
    elem = {[0] = 'mover', left, nucleus}
  elseif kind == 'udelimiterunder' then
    elem = {[0] = 'munder', nucleus, left}
  elseif kind == 'udelimiterover' then
    elem = {[0] = 'mover', nucleus, left}
  else
    error[[confusion]]
  end
  return do_sub_sup(elem, radical, cur_style)
end

local function fraction_to_table(fraction, sub, cur_style)
  local num = kernel_to_table(fraction.num, sup_style(cur_style))
  local denom = kernel_to_table(fraction.denom, sub_style(cur_style))
  local left = delim_to_table(fraction.left)
  local right = delim_to_table(fraction.right)
  local mfrac = {[0] = 'mfrac',
    linethickness = fraction.width and fraction.width == 0 and 0 or nil,
    bevelled = fraction.middle and "true" or nil,
    num,
    denom,
  }
  if left then
    return {[0] = 'mrow',
      left,
      mfrac,
      right, -- might be nil
    }
  elseif right then
    return {[0] = 'mrow',
      mfrac,
      right,
    }
  else
    return mfrac
  end
end

local function fence_to_table(fence, sub, cur_style)
  local delim = delim_to_table(fence.delimiter)
  delim.fence = 'true'
  return delim
end

local function space_to_table(amount, sub, cur_style)
  if amount == 0 then return end
  -- FIXME: What does MathML do in subscripts etc.? Probably we have to "unscale" in the non mu case...
  if sub == 99 then -- TODO magic number
    return {[0] = 'mspace', width = string.format("%.2fem", amount/18)}
  else
    return {[0] = 'mspace', width = string.format("%.2fem", amount/tex.sp'1em')}
  end
end

function nodes_to_table(head, cur_style)
  local t = {[0] = "mrow"}
  local result = t
  local nonscript
  for n, id, sub in node.traverse(head) do
    local props = properties[n] props = props and props.mathml_table
    if props then
      t[#t+1] = props
    elseif id == noad_t then
      t[#t+1] = noad_to_table(n, sub, cur_style)
    elseif id == accent_t then
      t[#t+1] = accent_to_table(n, sub, cur_style)
    elseif id == style_t then
      if #t ~= 0 then
        local new_t = {[0] = 'mstyle'}
        t[#t+1] = new_t
        t = new_t
      end
      if sub < 2 then
        t.displaystyle, t.scriptlevel = true, 0
      else
        t.displaystyle, t.scriptlevel = false, sub//2 - 1
      end
      cur_style = sub
    elseif id == choice_t then
      local size = cur_style//2
      t[#t+1] = nodes_to_table(n[size == 0 and 'display' or size == 1 and 'text'
                              or size == 2 and 'script'
                              or size == 3 and 'scriptscript' or assert(false)], 2*size)
    elseif id == radical_t then
      t[#t+1] = radical_to_table(n, sub, cur_style)
    elseif id == fraction_t then
      t[#t+1] = fraction_to_table(n, sub, cur_style)
    elseif id == fence_t then
      t[#t+1] = fence_to_table(n, sub, cur_style)
    elseif id == kern_t then
      if not nonscript then
        t[#t+1] = space_to_table(n.kern, sub, cur_style)
      end
    elseif id == glue_t then
      if cur_style >= 4 or not nonscript then
        if sub == 98 then -- TODO magic number
          nonscript = true
        else
          t[#t+1] = space_to_table(n.width, sub, cur_style)
        end
      end
    else
      t[#t+1] = {[0] = 'tex:TODO', other = n}
    end
    nonscript = nil
  end
  return result
end

local function register_remap(family, mapping)
  family = family << 21
  for from, to in next, mapping do
    remap_lookup[family | from] = utf8.char(to)
  end
end

local function to_mml(head, style)
  local result = nodes_to_table(head, style or 0)
  result[0] = 'math'
  result.xmlns = 'http://www.w3.org/1998/Math/MathML'
  result['xmlns:tex'] = 'http://typesetting.eu/2021/LuaMathML'
  if style == 2 then
    result.display = 'block'
  end
  return result
end

return {
  register_family = register_remap,
  process = to_mml,
}
