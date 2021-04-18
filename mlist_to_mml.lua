local noad_t, accent_t, style_t, choice_t = node.id'noad', node.id'accent', node.id'style', node.id'choice'
local radical_t, fraction_t, fence_t = node.id'radical', node.id'fraction', node.id'fence'

local math_char_t, sub_box_t, sub_mlist_t = node.id'math_char', node.id'sub_box', node.id'sub_mlist'

local noad_sub = node.subtypes'noad'
local radical_sub = node.subtypes'radical'
local fence_sub = node.subtypes'fence'

local nodes_to_table

-- We ignore large_... since they aren't used for modern fonts
local function delim_to_table(delim)
  if not delim then return end
  local fam = delim.small_fam
  return {[0] = 'mo', utf8.char(delim.small_char), ['tex:family'] = fam ~= 0 and fam or nil }
end

local function kernel_to_table(kernel)
  if not kernel then return end
  local id = kernel.id
  if id == math_char_t then
    local char = kernel.char
    local elem = char >= 0x30 and char < 0x39 and 'mn' or 'mi'
    local fam = kernel.fam
    return {[0] = elem, utf8.char(kernel.char), ['tex:family'] = fam ~= 0 and fam or nil }
  elseif id == sub_box_t then
    return {[0] = 'mi', {[0] = 'mglyph', ['tex:box'] = kernel.list}}
  elseif id == sub_mlist_t then
    return nodes_to_table(kernel.list)
  else
    error'confusion'
  end
end

local function do_sub_sup(t, n)
  sub = kernel_to_table(n.sub)
  sup = kernel_to_table(n.sup)
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

local function noad_to_table(noad, sub)
  local class = noad_sub[sub]
  local nucleus = kernel_to_table(noad.nucleus)
  if class == 'ord' then
  -- elseif class == 'opdisplaylimits' then
  -- elseif class == 'oplimits' then
  -- elseif class == 'opnolimits' then
  elseif class == 'bin' or class == 'rel' or class == 'open'
      or class == 'close' or class == 'punct' or class == 'inner' then
    if nucleus[0] == 'mrow' then
      -- TODO
    else
      nucleus[0] = 'mo'
    end
    nucleus['tex:class'] = class
  -- elseif class == 'under' then
  -- elseif class == 'over' then
  -- elseif class == 'vcenter' then
  else
  --   error[[confusion]]
    nucleus['tex:TODO'] = class
  end
  return do_sub_sup(nucleus, noad)
end

local function radical_to_table(radical, sub)
  local kind = radical_sub[sub]
  local nucleus = kernel_to_table(radical.nucleus)
  local left = delim_to_table(radical.left)
  local elem
  if kind == 'radical' or kind == 'uradical' then
    -- FIXME: Check that this is really a square root
    elem = {[0] = 'msqrt', nucleus}
  elseif kind == 'uroot' then
    -- FIXME: Check that this is really a root
    elem = {[0] = 'msqrt', nucleus, delim_to_table(radical.degree)}
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
  return do_sub_sup(elem, radical)
end

local function fraction_to_table(fraction, sub)
  local num = kernel_to_table(fraction.num)
  local denom = kernel_to_table(fraction.denom)
  local left = delim_to_table(fraction.left)
  -- local middle = delim_to_table(fraction.middle)
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

local function fence_to_table(fraction, sub)
  error[[TODO]]
  return {
    kind = fence_sub[sub],
  }
end

function nodes_to_table(head)
  local t = {[0] = "mrow"}
  for n, id, sub in node.traverse(head) do
    if id == noad_t then
      t[#t+1] = noad_to_table(n, sub)
    elseif id == accent_t then
      print(n)
      t[#t+1] = {[0] = 'TODO', accent = n}
    elseif id == style_t then
      print(n)
      t[#t+1] = {[0] = 'TODO', style = n}
    elseif id == choice_t then
      print(n)
      t[#t+1] = {[0] = 'TODO', choice = n}
    elseif id == radical_t then
      t[#t+1] = radical_to_table(n, sub)
    elseif id == fraction_t then
      t[#t+1] = fraction_to_table(n, sub)
    elseif id == fence_t then
      print(n)
      t[#t+1] = {[0] = 'TODO', fence = n}
    else
      print(n)
      t[#t+1] = n
    end
  end
  return t
end

return function(head)
  local result = nodes_to_table(head)
  result[0] = 'math'
  result.xmlns = 'http://www.w3.org/1998/Math/MathML'
  result['xmlns:tex'] = 'http://typesetting.eu/2021/LuaMathML'
  return result
end
