-- Test: Determinism - same seed + commands = same world
local luaunit = require("luaunit")
local world = require("src.world")
local sim = require("src.sim")
local orders = require("src.orders")

local function world_signature(w)
  local sig = {tick = w.tick, next_id = w.next_id, resources = {}, entities = {}}
  -- Resources
  for p = 1, w.num_players do
    sig.resources[p] = {}
    for res, val in pairs(w.resources[p]) do
      sig.resources[p][res] = val
    end
  end
  -- Entity kinds + positions + health
  for _, pair in ipairs(world.world_query(w, "kind")) do
    local eid = pair.eid
    local tag = pair.val.tag
    local pos = world.world_get(w, eid, "position")
    local hp = world.world_get(w, eid, "health")
    sig.entities[eid] = {tag = tag, x = pos and pos.x, y = pos and pos.y, hp = hp and hp.hp}
  end
  return sig
end

return {
  ["test-same-seed-same-result"] = function()
    local w1 = world.make_world({seed = 42})
    local w2 = world.make_world({seed = 42})
    -- Same setup
    for _, w in ipairs({w1, w2}) do
      world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
      world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
      world.spawn_bang(w, "tree", {x = 8, y = 6})
    end
    -- Same commands
    orders.issue_bang(w1, orders.gather(2, 4))
    orders.issue_bang(w2, orders.gather(2, 4))
    -- Run same ticks
    sim.run(w1, 50)
    sim.run(w2, 50)
    -- Signatures must match
    luaunit.assertEquals(world_signature(w1), world_signature(w2))
  end,

  ["test-different-seeds-diverge"] = function()
    -- Different seeds produce different RNG states
    -- We test this directly via the RNG, not via full simulation
    -- (because without commands, simulation is deterministic regardless of seed)
    local r1 = require("src.rng")
    local rng1 = r1.make_rng(1)
    local rng2 = r1.make_rng(999)
    local same = true
    for _ = 1, 10 do
      if r1.rng_next_bang(rng1) ~= r1.rng_next_bang(rng2) then
        same = false
      end
    end
    luaunit.assertFalse(same)
  end,

  ["test-snapshot-independence"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.spawn_bang(w, "tree", {x = 8, y = 6})
    sim.tick(w)
    local snap = world.snapshot(w)
    sim.run(w, 30)
    -- Snapshot should not have changed
    luaunit.assertEquals(snap.tick, 1)
    -- Live world should have advanced
    luaunit.assertEquals(w.tick, 31)
  end,
}
