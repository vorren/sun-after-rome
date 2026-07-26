-- Simple pretty-printer for Fennel/Lua values
-- Based on the fennelview concept
local function fennelview(x, depth)
  depth = depth or 0
  local t = type(x)
  if t == "string" then
    return string.format("%q", x)
  elseif t == "number" then
    return tostring(x)
  elseif t == "boolean" then
    return tostring(x)
  elseif t == "nil" then
    return "nil"
  elseif t == "table" then
    local parts = {}
    local is_array = #x > 0
    if is_array then
      for i, v in ipairs(x) do
        parts[i] = fennelview(v, depth + 1)
      end
      return "[" .. table.concat(parts, " ") .. "]"
    else
      for k, v in pairs(x) do
        local key
        if type(k) == "string" then
          key = ":" .. k
        else
          key = "[" .. fennelview(k, depth + 1) .. "]"
        end
        parts[#parts + 1] = key .. " " .. fennelview(v, depth + 1)
      end
      return "{" .. table.concat(parts, ", ") .. "}"
    end
  else
    return "<" .. t .. ">"
  end
end

return fennelview
