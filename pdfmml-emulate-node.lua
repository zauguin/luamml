local properties = {}
local subtypes = {
  noad = {[0] = 'ord', 'opdisplaylimits', 'oplimits', 'opnolimits', 'bin', 'rel', 'open', 'close', 'punct', 'inner', 'under', 'over', 'vcenter'},
  fence = {[0] = 'unset', 'left', 'middle', 'right', 'no'},
  radical = {[0] = 'radical', 'uradical', 'uroot', 'uunderdelimiter', 'uoverdelimiter', 'udelimiterunder', 'udelimiterover'},
}
local function traverse_iter(context, head)
  if head == nil then
    head = context
  else
    head = head.next
  end
  if head then
    return head, head.id, head.subtype
  else
    return nil
  end
end
node = {
  get_properties_table = function()
    return properties
  end,
  id = function(name)
    return name
  end,
  is_node = function(node)
    return type(node) == 'table' and node.id and true or false
  end,
  subtypes = function(id)
    return subtypes[id]
  end,
  traverse = function(head)
    return traverse_iter, head, nil
  end,
  direct = {
    todirect = function(n) return n end,
  },
}
tex.nulldelimiterspace = tex.nulldelimiterspace or 78643 -- 1.2pt
