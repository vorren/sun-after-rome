-- aurelius.systems.movement --- smooth movement with push collision.
-- ADR-0012: units walk toward destination with collision response.

local world = require("src.world")
local content = require("src.content")

local function cheby(x1, y1, x2, y2)
  return math.max(math.abs(x1 - x2), math.abs(y1 - y2))
end

local function entity_pos(w, eid)
  local p = world.world_get(w, eid, "position")
  if p then
    return p.x, p.y
  end
end

local function speed_of(w, eid)
  local tag = w.store.kind[eid].tag
  return content.kind_stat(tag, "speed", 1)
end

local function collision_radius(w, eid)
  local tag = w.store.kind[eid].tag
  return content.kind_stat(tag, "collision-radius", 0) or 0
end

local function entity_at_tile(w, x, y, exclude_eid)
  local best = nil
  local best_dist = nil
  for _, pair in ipairs(world.world_query(w, "position")) do
    local eid = pair.eid
    local pos = pair.val
    if eid ~= exclude_eid then
      local d = cheby(pos.x, pos.y, x, y)
      if (best_dist == nil) or (d < best_dist) then
        best = eid
        best_dist = d
      end
    end
  end
  return best
end

-- Check if entity blocks movement (has :blocks true in content).
local function blocks_movement(w, eid)
  local kind = world.world_get(w, eid, "kind")
  if kind then
    return content.kind_stat(kind.tag, "blocks", false)
  end
end

local function would_collide(w, eid, tx, ty)
  local other = entity_at_tile(w, tx, ty, eid)
  if other then
    -- buildings with :blocks true always block
    if blocks_movement(w, other) then
      return true
    else
      -- units collide based on collision radius
      local cr = collision_radius(w, eid)
      local or2 = collision_radius(w, other)
      return (cr + or2) < 1.0
    end
  end
end

local function push_entity(w, eid, tx, ty)
  local other = entity_at_tile(w, tx, ty, eid)
  if other then
    local op = world.world_get(w, other, "position")
    local ep = world.world_get(w, eid, "position")
    if op and ep then
      local dx = ep.x - op.x
      local dy = ep.y - op.y
      if (dx == 0) and (dy == 0) then
        dx = 1
      end
      local dist = math.sqrt(dx * dx + dy * dy)
      local nx = dx / dist
      local ny = dy / dist
      local cr = collision_radius(w, eid)
      local or2 = collision_radius(w, other)
      local push_dist = 0.3 * (cr + or2)
      local push_x = op.x + nx * push_dist
      local push_y = op.y + ny * push_dist
      op.x = math.max(0, math.min(w.width - 1, push_x))
      op.y = math.max(0, math.min(w.height - 1, push_y))
    end
  end
end

local function step_toward(w, eid, tx, ty)
  local p = world.world_get(w, eid, "position")
  local spd = speed_of(w, eid)
  local dx = tx - p.x
  local dy = ty - p.y
  local dist = math.sqrt(dx * dx + dy * dy)
  if dist > 0.01 then
    local step = math.min(spd, dist)
    local nx = dx / dist
    local ny = dy / dist
    local new_x = p.x + nx * step
    local new_y = p.y + ny * step
    local clamp_x = math.max(0, math.min(w.width - 1, new_x))
    local clamp_y = math.max(0, math.min(w.height - 1, new_y))
    if would_collide(w, eid, clamp_x, clamp_y) then
      push_entity(w, eid, clamp_x, clamp_y)
    end
    p.x = clamp_x
    p.y = clamp_y
  end
end

local function at_tile(w, eid, tx, ty)
  local p = world.world_get(w, eid, "position")
  return cheby(p.x, p.y, tx, ty) <= 0.5
end

local function within(w, eid, tx, ty, dist)
  local p = world.world_get(w, eid, "position")
  return cheby(p.x, p.y, tx, ty) <= dist
end

local function movement_system(w)
  for _, pair in ipairs(world.world_query(w, "task")) do
    local eid = pair.eid
    local t = pair.val
    if t.kind == "move" then
      if at_tile(w, eid, t.tx, t.ty) then
        t.kind = "idle"
      else
        step_toward(w, eid, t.tx, t.ty)
      end
    end
  end
end

return {
  cheby = cheby,
  entity_pos = entity_pos,
  speed_of = speed_of,
  collision_radius = collision_radius,
  entity_at_tile = entity_at_tile,
  would_collide = would_collide,
  push_entity = push_entity,
  step_toward = step_toward,
  at_tile = at_tile,
  within = within,
  movement_system = movement_system
}
