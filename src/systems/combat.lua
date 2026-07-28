-- aurelius.systems.combat --- melee & ranged fighting with AOE2-style
-- armour-class bonus damage (ADR-0010).

local world = require("src.world")
local content = require("src.content")
local rng = require("src.rng")
local movement = require("src.systems.movement")

local function armour_class_of(w, eid)
  local tag = w.store.kind[eid].tag
  return content.kind_stat(tag, "armour", "none")
end

-- Deterministic damage roll
local function attack_damage(w, attacker, target)
  local tag = w.store.kind[attacker].tag
  local prof = content.attack_of(tag)
  local tcls = armour_class_of(w, target)
  local bonus = prof.bonus_vs[tcls] or 0
  local raw = world.effective_damage(w, attacker, prof.damage + bonus)
  local factor = rng.rng_range(w.rng, 95, 105)
  return math.max(1, math.floor(raw * factor / 100))
end

local function dead(w, eid)
  return not world.world_has(w, eid, "health")
end

local function strike(w, a, tgt)
  local h = world.world_get(w, tgt, "health")
  local hp = h.hp - attack_damage(w, a, tgt)
  if hp <= 0 then
    world.world_remove_entity(w, tgt)
  else
    h.hp = hp
  end
end

local function combat_system(w)
  -- 1. cool everyone down
  for _, pair in ipairs(world.world_query(w, "cooldown")) do
    local c = pair.val
    if c.ticks > 0 then
      c.ticks = c.ticks - 1
    end
  end
  -- 2. resolve attack tasks
  for _, pair in ipairs(world.world_query(w, "task")) do
    local a = pair.eid
    local t = pair.val
    if (t.kind == "attack") and world.world_has(w, a, "kind") then
      local tgt = t.target
      if (tgt == nil) or dead(w, tgt) then
        t.kind = "idle"
      else
        local tpx, tpy = movement.entity_pos(w, tgt)
        local tag = w.store.kind[a].tag
        local prof = content.attack_of(tag)
        t.tx = tpx
        t.ty = tpy
        if movement.within(w, a, tpx, tpy, prof.range) then
          local cd = world.world_get(w, a, "cooldown")
          if cd and cd.ticks == 0 then
            strike(w, a, tgt)
            cd.ticks = prof.cooldown
          end
        else
          movement.step_toward(w, a, tpx, tpy)
        end
      end
    end
  end
end

return {combat_system = combat_system, attack_damage = attack_damage}
