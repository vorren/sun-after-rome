-- Test: World creation and entity lifecycle
local luaunit = require("luaunit")
local world = require("src.world")
local content = require("src.content")

return {
  ["test-make-world"] = function()
    local w = world.make_world({width = 10, height = 8, players = 2, seed = 42})
    luaunit.assertEquals(w.width, 10)
    luaunit.assertEquals(w.height, 8)
    luaunit.assertEquals(w.num_players, 2)
    luaunit.assertEquals(w.tick, 0)
    luaunit.assertEquals(w.next_id, 1)
  end,

  ["test-spawn-entity"] = function()
    local w = world.make_world({seed = 42})
    local id = world.spawn_bang(w, "villager", {owner = 0, x = 5, y = 5})
    luaunit.assertNotNil(id)
    luaunit.assertTrue(world.world_has(w, id, "kind"))
    luaunit.assertTrue(world.world_has(w, id, "position"))
    luaunit.assertTrue(world.world_has(w, id, "owner"))
    luaunit.assertTrue(world.world_has(w, id, "health"))
    luaunit.assertTrue(world.world_has(w, id, "carry"))
    luaunit.assertTrue(world.world_has(w, id, "task"))
  end,

  ["test-remove-entity"] = function()
    local w = world.make_world({seed = 42})
    local id = world.spawn_bang(w, "villager", {owner = 0, x = 5, y = 5})
    luaunit.assertTrue(world.world_has(w, id, "kind"))
    world.world_remove_entity(w, id)
    luaunit.assertFalse(world.world_has(w, id, "kind"))
  end,

  ["test-world-query-sorted"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "villager", {owner = 0, x = 1, y = 1})
    world.spawn_bang(w, "villager", {owner = 0, x = 2, y = 2})
    world.spawn_bang(w, "villager", {owner = 0, x = 3, y = 3})
    local q = world.world_query(w, "kind")
    luaunit.assertEquals(#q, 3)
    -- Verify sorted by eid
    luaunit.assertTrue(q[1].eid < q[2].eid)
    luaunit.assertTrue(q[2].eid < q[3].eid)
  end,

  ["test-resources"] = function()
    local w = world.make_world({seed = 42})
    luaunit.assertEquals(world.resource_amount(w, 1, "wood"), 0)
    world.add_resource_bang(w, 1, "wood", 100)
    luaunit.assertEquals(world.resource_amount(w, 1, "wood"), 100)
    luaunit.assertTrue(world.can_afford_q(w, 1, {wood = 50}))
    luaunit.assertFalse(world.can_afford_q(w, 1, {wood = 150}))
    world.pay_bang(w, 1, {wood = 30})
    luaunit.assertEquals(world.resource_amount(w, 1, "wood"), 70)
  end,
}
