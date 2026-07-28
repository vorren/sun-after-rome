-- aurelius.world --- the world value: entity/component store, per-player resources,
-- ages, RNG, and snapshot/restore.
-- ADR-0003/0004/0005/0006.

local components = require("src.components")
local content = require("src.content")
local rng = require("src.rng")

local component_types =
  {"position", "owner", "kind", "health", "carry", "node", "cooldown", "producer", "task"}

local function make_world(opts)
  local width = opts.width
  local height = opts.height
  local players = opts.players
  local seed = opts.seed
  local store = {}
  for _, ct in ipairs(component_types) do
    store[ct] = {}
  end
  return {
    tick = 0,
    width = width or 24,
    height = height or 16,
    num_players = players or 2,
    store = store,
    resources = (function()
      local r = {}
      for p = 1, (players or 2) do
        r[p] = {}
      end
      return r
    end)(),
    ages = (function()
      local a = {}
      for p = 1, (players or 2) do
        a[p] = 1
      end
      return a
    end)(),
    age_progress = (function()
      local ap = {}
      for p = 1, (players or 2) do
        ap[p] = nil
      end
      return ap
    end)(),
    rng = rng.make_rng(seed or 1),
    orders = {},
    log = {},
    next_id = 1,
    controllers = (function()
      local c = {}
      for p = 1, (players or 2) do
        c[p] = {type = "idle"}
      end
      return c
    end)()
  }
end

-- Entity + component store
local function fresh_id(w)
  local id = w.next_id
  w.next_id = id + 1
  return id
end

local function ctype_table(w, ct)
  return w.store[ct] or error("unknown component type: " .. tostring(ct))
end

local function world_add(w, eid, ct, value)
  ctype_table(w, ct)[eid] = value
  return value
end

local function world_get(w, eid, ct)
  return ctype_table(w, ct)[eid]
end

local function world_has(w, eid, ct)
  return ctype_table(w, ct)[eid] ~= nil
end

local function world_remove_component(w, eid, ct)
  ctype_table(w, ct)[eid] = nil
end

-- All entities holding component CT, sorted by eid (determinism).
local function world_query(w, ct)
  local t = ctype_table(w, ct)
  local result = {}
  for eid, val in pairs(t) do
    table.insert(result, {eid = eid, val = val})
  end
  table.sort(result, function(a, b) return a.eid < b.eid end)
  return result
end

-- All live entity ids (anything with a kind), sorted.
local function world_entities(w)
  local result = {}
  for _, pair in ipairs(world_query(w, "kind")) do
    table.insert(result, pair.eid)
  end
  return result
end

local function world_remove_entity(w, eid)
  for _, ct in ipairs(component_types) do
    ctype_table(w, ct)[eid] = nil
  end
end

-- Controllers (ADR-0015)
local function set_controller(w, p, ctrl)
  w.controllers[p + 1] = ctrl
end

local function get_controller(w, p)
  return w.controllers[p + 1]
end

-- Ages (ADR-0011) - defined early so effective-* can use them
-- Player indices are 0-based in game logic, 1-based in Lua tables
local function player_age(w, p) return w.ages[p + 1] end
local function set_player_age(w, p, level) w.ages[p + 1] = level end
local function age_progress(w, p) return w.age_progress[p + 1] end
local function set_age_progress(w, p, v) w.age_progress[p + 1] = v end

-- Effective (age-adjusted) stats (ADR-0011) - must come before spawn!
local function owner_of(w, eid)
  local o = world_get(w, eid, "owner")
  return o and o.player
end

local function mult(w, eid, key)
  local p = owner_of(w, eid)
  if p and p >= 0 then
    return content.age_bonus(player_age(w, p), key)
  else
    return 1
  end
end

local function effective_max_hp(w, eid)
  local tag = w.store["kind"][eid].tag
  return math.floor(content.base_max_hp(tag) * mult(w, eid, "hp"))
end

local function effective_gather_rate(w, eid)
  local tag = w.store["kind"][eid].tag
  return math.floor(content.kind_stat(tag, "gather-rate", 0) * mult(w, eid, "gather"))
end

local function effective_damage(w, eid, base)
  return math.floor(base * mult(w, eid, "damage"))
end

-- Spawning: build an entity's components from its content kind.
local function spawn(w, tag, opts)
  local id = fresh_id(w)
  opts = opts or {}
  world_add(w, id, "kind", components.make_kind(tag))
  world_add(w, id, "position", components.make_position(opts.x or 0, opts.y or 0))
  if opts.owner then
    world_add(w, id, "owner", components.make_owner(opts.owner))
  end
  -- health for anything with hit points
  local hp = content.kind_stat(tag, "max-hp")
  if hp then
    world_add(w, id, "health", components.make_health(content.base_max_hp(tag)))
    local h = world_get(w, id, "health")
    h.hp = effective_max_hp(w, id)
  end
  -- resource node
  local res = content.kind_stat(tag, "node")
  if res then
    world_add(w, id, "node", components.make_node(res, content.kind_stat(tag, "amount", 0)))
  end
  -- production building
  if #content.producer_trains(tag) > 0 then
    world_add(w, id, "producer", components.make_producer({}, 0))
  end
  -- villager cargo
  if tag == "villager" then
    world_add(w, id, "carry", components.make_carry(nil, 0))
  end
  -- military attack cooldown + idle task
  if content.kind_stat(tag, "damage", 0) > 0 then
    world_add(w, id, "cooldown", components.make_cooldown(0))
  end
  if tag == "villager" or content.kind_stat(tag, "damage", 0) > 0 then
    world_add(w, id, "task", components.make_task("idle", nil, nil, nil, nil))
  end
  return id
end

-- Resources (ADR-0008)
local function resource_amount(w, p, res)
  return w.resources[p + 1][res] or 0
end

local function add_resource(w, p, res, n)
  local current = resource_amount(w, p, res)
  w.resources[p + 1][res] = current + n
end

local function can_afford(w, p, cost)
  local ok = true
  for res, amount in pairs(cost) do
    if resource_amount(w, p, res) < amount then
      ok = false
    end
  end
  return ok
end

local function pay(w, p, cost)
  if can_afford(w, p, cost) then
    for res, amount in pairs(cost) do
      add_resource(w, p, res, -amount)
    end
    return true
  end
end

-- Snapshot / restore (ADR-0004): deep independent copy.
local function copy_table(t)
  local out = {}
  for k, v in pairs(t) do
    out[k] = type(v) == "table" and copy_table(v) or v
  end
  return out
end

local function copy_component(ct, v)
  if ct == "position" then
    return components.make_position(v.x, v.y)
  elseif ct == "owner" then
    return components.make_owner(v.player)
  elseif ct == "kind" then
    return components.make_kind(v.tag)
  elseif ct == "health" then
    return components.make_health(v.hp)
  elseif ct == "carry" then
    return components.make_carry(v.resource, v.amount)
  elseif ct == "node" then
    return components.make_node(v.resource, v.amount)
  elseif ct == "cooldown" then
    return components.make_cooldown(v.ticks)
  elseif ct == "producer" then
    return components.make_producer(copy_table(v.queue), v.progress)
  elseif ct == "task" then
    return components.make_task(v.kind, v.target, v.tx, v.ty, v.phase)
  else
    return copy_table(v)
  end
end

local function snapshot(w)
  local store = {}
  for _, ct in ipairs(component_types) do
    local src = w.store[ct]
    local dst = {}
    for eid, v in pairs(src) do
      dst[eid] = copy_component(ct, v)
    end
    store[ct] = dst
  end
  return {
    tick = w.tick,
    width = w.width,
    height = w.height,
    num_players = w.num_players,
    store = store,
    resources = copy_table(w.resources),
    ages = copy_table(w.ages),
    age_progress = copy_table(w.age_progress),
    rng = rng.make_rng(rng.rng_state(w.rng)),
    orders = copy_table(w.orders),
    log = copy_table(w.log),
    next_id = w.next_id,
    controllers = copy_table(w.controllers)
  }
end

return {
  ["make-world"] = make_world,
  ["fresh-id!"] = fresh_id,
  ["world-add!"] = world_add,
  ["world-get"] = world_get,
  ["world-has?"] = world_has,
  ["world-remove-component!"] = world_remove_component,
  ["world-query"] = world_query,
  ["world-remove-entity!"] = world_remove_entity,
  ["world-entities"] = world_entities,
  ["spawn!"] = spawn,
  ["set-controller!"] = set_controller,
  ["get-controller"] = get_controller,
  ["player-age"] = player_age,
  ["set-player-age!"] = set_player_age,
  ["age-progress"] = age_progress,
  ["set-age-progress!"] = set_age_progress,
  ["effective-max-hp"] = effective_max_hp,
  ["effective-gather-rate"] = effective_gather_rate,
  ["effective-damage"] = effective_damage,
  ["owner-of"] = owner_of,
  ["resource-amount"] = resource_amount,
  ["add-resource!"] = add_resource,
  ["can-afford?"] = can_afford,
  ["pay!"] = pay,
  ["snapshot"] = snapshot,
  ["component-types"] = component_types
}
