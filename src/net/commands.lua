-- aurelius.net.commands --- command serialization for network transport.
-- Commands are already data (tagged tables); serialize via string operations.

local function serialize_order(order)
  if order.tag == "move" then
    return string.format("m:%d:%d:%d", order.eid, order.tx, order.ty)
  elseif order.tag == "gather" then
    return string.format("g:%d:%d", order.eid, order.node)
  elseif order.tag == "attack" then
    return string.format("a:%d:%d", order.eid, order.target)
  elseif order.tag == "train" then
    return string.format("t:%d:%s", order.prod, order.unit)
  elseif order.tag == "advance_age" then
    return string.format("u:%d", order.player)
  else
    return ""
  end
end

-- Split a string by a delimiter (since Fennel doesn't like str:gsub)
local function split(str, delim)
  local result = {}
  local start = 1
  local done = false
  while not done do
    local pos = string.find(str, delim, start, true)
    if pos then
      table.insert(result, string.sub(str, start, pos - 1))
      start = pos + 1
    else
      table.insert(result, string.sub(str, start))
      done = true
    end
  end
  return result
end

local function deserialize_order(str)
  local parts = split(str, ":")
  local tag = parts[1]
  if tag == "m" then
    return {tag = "move", eid = tonumber(parts[2]), tx = tonumber(parts[3]), ty = tonumber(parts[4])}
  elseif tag == "g" then
    return {tag = "gather", eid = tonumber(parts[2]), node = tonumber(parts[3])}
  elseif tag == "a" then
    return {tag = "attack", eid = tonumber(parts[2]), target = tonumber(parts[3])}
  elseif tag == "t" then
    return {tag = "train", prod = tonumber(parts[2]), unit = parts[3]}
  elseif tag == "u" then
    return {tag = "advance-age", player = tonumber(parts[2])}
  else
    return nil
  end
end

local function serialize_commands(cmds)
  local parts = {}
  for _, cmd in ipairs(cmds) do
    local s = serialize_order(cmd)
    if #s > 0 then
      table.insert(parts, s)
    end
  end
  return table.concat(parts, "|")
end

local function deserialize_commands(str)
  local cmds = {}
  if str and #str > 0 then
    local parts = split(str, "|")
    for _, s in ipairs(parts) do
      local cmd = deserialize_order(s)
      if cmd then
        table.insert(cmds, cmd)
      end
    end
  end
  return cmds
end

return {
  serialize_order = serialize_order,
  deserialize_order = deserialize_order,
  serialize_commands = serialize_commands,
  deserialize_commands = deserialize_commands,
}
