-- aurelius.render.interpolation --- frame interpolation between ticks.
-- Stores previous positions and provides alpha for smooth rendering.

local world = require("src.world")

local prev_positions = {}
local alpha = 0

local function save_positions(w)
  -- Save current positions before tick for interpolation.
  prev_positions = {}
  for _, pair in ipairs(world.world_query(w, "position")) do
    local eid = pair.eid
    local pos = pair.val
    prev_positions[eid] = {x = pos.x, y = pos.y}
  end
end

local function set_alpha(a)
  -- Set interpolation alpha (0..1) based on accumulator.
  alpha = a
end

local function get_alpha()
  -- Get current interpolation alpha.
  return alpha
end

local function interpolated_pos(w, eid)
  -- Get interpolated position for entity EID.
  local curr = world.world_get(w, eid, "position")
  local prev = prev_positions[eid]
  if curr then
    if prev and alpha < 1 then
      return {
        x = prev.x + (curr.x - prev.x) * alpha,
        y = prev.y + (curr.y - prev.y) * alpha
      }
    else
      return curr
    end
  end
end

local function clear()
  -- Clear interpolation state.
  prev_positions = {}
  alpha = 0
end

return {
  ["save-positions"] = save_positions,
  save_positions = save_positions,
  ["set-alpha"] = set_alpha,
  set_alpha = set_alpha,
  ["get-alpha"] = get_alpha,
  get_alpha = get_alpha,
  ["interpolated-pos"] = interpolated_pos,
  interpolated_pos = interpolated_pos,
  ["clear"] = clear
}
