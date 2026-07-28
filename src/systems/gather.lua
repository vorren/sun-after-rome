-- aurelius.systems.gather --- villagers harvest nodes and deposit at a TC.
-- Phase machine: to-node -> gathering -> to-drop.
-- Gather RATE scales with age (ADR-0011).

local world = require("src.world")
local content = require("src.content")
local movement = require("src.systems.movement")

local function owner_of(w, eid)
  local o = world.world_get(w, eid, "owner")
  return o and o.player
end

-- Nearest own Town Centre
local function nearest_dropoff(w, villager)
  local pl = owner_of(w, villager)
  local vx, vy = movement.entity_pos(w, villager)
  if pl and vx then
    local best = nil
    local bd = nil
    for _, pair in ipairs(world.world_query(w, "kind")) do
      local eid = pair.eid
      local tag = pair.val.tag
      local own = world.world_get(w, eid, "owner")
      if (tag == "town-centre") and own and (own.player == pl) then
        local px, py = movement.entity_pos(w, eid)
        local d = movement.cheby(vx, vy, px, py)
        if (bd == nil) or (d < bd) then
          best = eid
          bd = d
        end
      end
    end
    return best
  end
end

local function go_idle(t)
  t.kind = "idle"
  t.phase = nil
end

local function aim(w, t, eid)
  local px, py = movement.entity_pos(w, eid)
  if px then
    t.tx = px
    t.ty = py
  end
end

local function start_drop(w, v, t)
  local tc = nearest_dropoff(w, v)
  if tc then
    t.phase = "to-drop"
    aim(w, t, tc)
  else
    go_idle(t)
  end
end

local function dropoff_adjacent(w, v)
  local tc = nearest_dropoff(w, v)
  if tc then
    local px, py = movement.entity_pos(w, tc)
    if movement.within(w, v, px, py, 1) then
      return tc
    end
  end
end

local function gather_system(w)
  for _, pair in ipairs(world.world_query(w, "task")) do
    local v = pair.eid
    local t = pair.val
    if t.kind == "gather" then
      local node_id = t.target
      local node = node_id and world.world_get(w, node_id, "node")
      local cargo = world.world_get(w, v, "carry")

      if t.phase == "to-node" then
        if not node then
          go_idle(t)
        elseif movement.within(w, v, t.tx, t.ty, 1) then
          t.phase = "gathering"
        else
          movement.step_toward(w, v, t.tx, t.ty)
        end

      elseif t.phase == "gathering" then
        if not node then
          if cargo.amount > 0 then
            start_drop(w, v, t)
          else
            go_idle(t)
          end
        else
          if not cargo.resource then
            cargo.resource = node.resource
          end
          local tag = w.store.kind[v].tag
          local cap = content.gather_capacity(tag)
          local want = math.max(1, world.effective_gather_rate(w, v))
          local got = math.min(want, node.amount, cap - cargo.amount)
          cargo.amount = cargo.amount + got
          node.amount = node.amount - got
          if node.amount <= 0 then
            world.world_remove_entity(w, node_id)
          end
          if cargo.amount >= cap then
            start_drop(w, v, t)
          end
        end

      elseif t.phase == "to-drop" then
        local dropoff = dropoff_adjacent(w, v)
        if dropoff then
          world.add_resource(w, owner_of(w, v), cargo.resource, cargo.amount)
          cargo.amount = 0
          cargo.resource = nil
          if node then
            t.phase = "to-node"
            aim(w, t, node_id)
          else
            go_idle(t)
          end
        else
          movement.step_toward(w, v, t.tx, t.ty)
        end

      else
        -- default: go idle
        go_idle(t)
      end
    end
  end
end

return {gather_system = gather_system, nearest_dropoff = nearest_dropoff}
