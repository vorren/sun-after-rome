-- src.ai.scripted --- scripted AI controller for v1.
-- Deterministic build order with guards. Runs as a system in the tick pipeline.
-- ADR-0016: AI as deterministic tick system.

local world = require("src.world")
local content = require("src.content")
local orders = require("src.orders")
local personalities = require("src.ai.personalities")

-- ---- Query helpers ----

-- All entities owned by FACTION, sorted by eid.
local function faction_entities(w, faction)
  local result = {}
  for _, pair in ipairs(world["world-query"](w, "owner")) do
    if pair.val.player == faction then
      table.insert(result, pair.eid)
    end
  end
  table.sort(result, function(a, b)
    return a < b
  end)
  return result
end

-- Does FACTION own a building of TAG?
local function has_building(w, faction, tag)
  local found = false
  for _, eid in ipairs(faction_entities(w, faction)) do
    local kind = world["world-get"](w, eid, "kind")
    if kind and kind.tag == tag then
      local owner = world["world-get"](w, eid, "owner")
      if owner and owner.player == faction then
        found = true
      end
    end
  end
  return found
end

-- Get the first building eid of TAG owned by FACTION, or nil.
local function get_building(w, faction, tag)
  local result = nil
  for _, eid in ipairs(faction_entities(w, faction)) do
    if not result then
      local kind = world["world-get"](w, eid, "kind")
      if kind and kind.tag == tag then
        local owner = world["world-get"](w, eid, "owner")
        if owner and owner.player == faction then
          result = eid
        end
      end
    end
  end
  return result
end

-- Count units of TAG owned by FACTION.
local function count_units(w, faction, tag)
  local n = 0
  for _, eid in ipairs(faction_entities(w, faction)) do
    local kind = world["world-get"](w, eid, "kind")
    if kind and kind.tag == tag then
      local owner = world["world-get"](w, eid, "owner")
      if owner and owner.player == faction then
        n = n + 1
      end
    end
  end
  return n
end

-- Villagers owned by FACTION with idle task.
local function idle_villagers(w, faction)
  local result = {}
  for _, eid in ipairs(faction_entities(w, faction)) do
    local kind = world["world-get"](w, eid, "kind")
    local task = world["world-get"](w, eid, "task")
    if kind and kind.tag == "villager" and task and task.kind == "idle" then
      table.insert(result, eid)
    end
  end
  table.sort(result, function(a, b)
    return a < b
  end)
  return result
end

-- Nearest node of RESOURCE-TYPE to entity EID, or nil.
local function nearest_node(w, eid, resource_type)
  local pos = world["world-get"](w, eid, "position")
  if pos then
    local best = nil
    local best_dist = nil
    for _, pair in ipairs(world["world-query"](w, "node")) do
      local node = pair.val
      local node_pos = world["world-get"](w, pair.eid, "position")
      if node_pos and node.resource == resource_type then
        local d = math.abs(pos.x - node_pos.x) + math.abs(pos.y - node_pos.y)
        if best_dist == nil or d < best_dist then
          best = pair.eid
          best_dist = d
        end
      end
    end
    return best
  end
  return nil
end

-- Nearest entity with health owned by an enemy of FACTION.
local function nearest_enemy(w, faction)
  local best = nil
  local best_dist = nil
  for _, pair in ipairs(world["world-query"](w, "owner")) do
    if pair.val.player ~= faction then
      local eid = pair.eid
      local epos = world["world-get"](w, eid, "position")
      local h = world["world-get"](w, eid, "health")
      if epos and h then
        local my_eid = faction_entities(w, faction)[1]
        if my_eid then
          local mpos = world["world-get"](w, my_eid, "position")
          if mpos then
            local dx = mpos.x - epos.x
            local dy = mpos.y - epos.y
            local d = math.abs(dx) + math.abs(dy)
            if best_dist == nil or d < best_dist then
              best = eid
              best_dist = d
            end
          end
        end
      end
    end
  end
  return best
end

-- ---- Resource gathering helpers ----

-- Count villagers gathering RESOURCE-TYPE.
local function count_gatherers(w, faction, resource_type)
  local n = 0
  for _, eid in ipairs(faction_entities(w, faction)) do
    local kind = world["world-get"](w, eid, "kind")
    local task = world["world-get"](w, eid, "task")
    if kind and kind.tag == "villager" and task and task.kind == "gather" then
      local node = world["world-get"](w, task.target, "node")
      if node and node.resource == resource_type then
        n = n + 1
      end
    end
  end
  return n
end

-- Pick which resource type an idle villager should gather based on personality ratios.
local function pick_resource_for_villager(w, faction, personality)
  local villager_count = count_units(w, faction, "villager")
  local wood_gatherers = count_gatherers(w, faction, "wood")
  local gold_gatherers = count_gatherers(w, faction, "gold")
  local stone_gatherers = count_gatherers(w, faction, "stone")
  local wood_target = personality["wood-ratio"] and math.floor(villager_count * personality["wood-ratio"]) or 0
  local gold_target = personality["gold-ratio"] and math.floor(villager_count * personality["gold-ratio"]) or 0
  local stone_target = personality["stone-ratio"] and math.floor(villager_count * personality["stone-ratio"]) or 0
  if wood_gatherers < wood_target then
    return "wood"
  elseif gold_gatherers < gold_target then
    return "gold"
  elseif stone_gatherers < stone_target then
    return "stone"
  else
    return "wood"
  end
end

-- ---- Build order phases ----

-- Train villagers from TC until we reach personality's villager-target.
local function train_villagers(w, faction, personality)
  local count = count_units(w, faction, "villager")
  local tc = get_building(w, faction, "town-centre")
  local target = personality["villager-target"] or 6
  if tc and count < target then
    local cost = content["unit-cost"]("villager")
    if world["can-afford?"](w, faction, cost) then
      orders["issue!"](w, orders["train"](tc, "villager"))
      return true
    end
  end
  return nil
end

-- Send idle villagers to gather resources based on personality ratios.
local function gather_resources(w, faction, personality)
  local vills = idle_villagers(w, faction)
  for _, eid in ipairs(vills) do
    local resource_type = pick_resource_for_villager(w, faction, personality)
    local node = nearest_node(w, eid, resource_type)
    if node then
      orders["issue!"](w, orders["gather"](eid, node))
    end
  end
end

-- Advance to age 2 if we can afford it.
local function advance_age_if_ready(w, faction)
  local age = world["player-age"](w, faction)
  if age == 1 then
    local cost = content["age-cost"](2)
    if world["can-afford?"](w, faction, cost) then
      orders["issue!"](w, orders["advance-age"](faction))
      return true
    end
  end
  return nil
end

-- Train knights from barracks if military threshold not met.
local function train_knights(w, faction, personality)
  local barracks = get_building(w, faction, "barracks")
  local military_count = count_units(w, faction, "knight")
  local threshold = personality["military-threshold"] or 3
  if barracks and military_count < threshold then
    local cost = content["unit-cost"]("knight")
    if world["can-afford?"](w, faction, cost) then
      orders["issue!"](w, orders["train"](barracks, "knight"))
      return true
    end
  end
  return nil
end

-- Send idle military units to attack the nearest enemy if attack-when-idle enabled.
local function attack_with_military(w, faction, personality)
  if personality["attack-when-idle"] then
    local target = nearest_enemy(w, faction)
    if target then
      for _, eid in ipairs(faction_entities(w, faction)) do
        local kind = world["world-get"](w, eid, "kind")
        local task = world["world-get"](w, eid, "task")
        if kind and task and task.kind == "idle"
            and content["kind-stat"](kind.tag, "damage", 0) > 0 then
          orders["issue!"](w, orders["attack"](eid, target))
        end
      end
    end
  end
end

-- ---- Main AI system ----

-- Run one tick of the scripted AI for FACTION with PERSONALITY.
local function ai_system(w, faction, personality)
  local personality = personality or personalities["default-personality"]()
  -- Phase 1: Economy — train villagers
  train_villagers(w, faction, personality)
  -- Phase 2: Resource gathering
  gather_resources(w, faction, personality)
  -- Phase 3: Age advancement (when affordable)
  advance_age_if_ready(w, faction)
  -- Phase 4: Military production
  train_knights(w, faction, personality)
  -- Phase 5: Attack
  attack_with_military(w, faction, personality)
end

-- Create an AI controller bound to FACTION with PERSONALITY.
local function make_ai_controller(faction, personality)
  local personality = personality or personalities["default-personality"]()
  return {
    type = "ai",
    faction = faction,
    personality = personality,
    tick = function(w)
      return ai_system(w, faction, personality)
    end,
  }
end

-- Create an AI takeover controller for a disconnected player.
local function make_ai_takeover(faction)
  return make_ai_controller(faction, personalities["default-personality"]())
end

return {
  ["ai-system"] = ai_system,
  ai_system = ai_system,
  ["make-ai-controller"] = make_ai_controller,
  make_ai_controller = make_ai_controller,
  ["make-ai-takeover"] = make_ai_takeover,
  make_ai_takeover = make_ai_takeover,
  ["faction-entities"] = faction_entities,
  faction_entities = faction_entities,
  ["has-building?"] = has_building,
  ["has_building?"] = has_building,
  ["get-building"] = get_building,
  get_building = get_building,
  ["count-units"] = count_units,
  count_units = count_units,
  ["idle-villagers"] = idle_villagers,
  idle_villagers = idle_villagers,
  ["nearest-node"] = nearest_node,
  nearest_node = nearest_node,
  ["nearest-enemy"] = nearest_enemy,
  nearest_enemy = nearest_enemy,
}
