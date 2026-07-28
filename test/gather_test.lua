-- Test: Gathering system
local luaunit = require("luaunit")
local world = require("src.world")
local sim = require("src.sim")
local orders = require("src.orders")

return {
  ["test-gather-deposits-resources"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.spawn_bang(w, "tree", {x = 5, y = 4})
    orders.issue_bang(w, orders.gather(2, 3))
    sim.run(w, 40)
    local wood = world.resource_amount(w, 0, "wood")
    luaunit.assertTrue(wood > 0)
  end,

  ["test-node-depletion"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 3, y = 4})
    local tree = world.spawn_bang(w, "tree", {x = 3, y = 5})
    world.world_get(w, tree, "node")
    local node = world.world_get(w, tree, "node")
    node.amount = 5
    orders.issue_bang(w, orders.gather(2, tree))
    sim.run(w, 50)
    luaunit.assertFalse(world.world_has(w, tree, "node"))
  end,

  ["test-multiple-resource-types"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 5})
    world.spawn_bang(w, "tree", {x = 5, y = 4})
    world.spawn_bang(w, "gold-mine", {x = 5, y = 5})
    orders.issue_bang(w, orders.gather(2, 4))
    orders.issue_bang(w, orders.gather(3, 5))
    sim.run(w, 50)
    local wood = world.resource_amount(w, 0, "wood")
    local gold = world.resource_amount(w, 0, "gold")
    luaunit.assertTrue(wood > 0)
    luaunit.assertTrue(gold > 0)
  end,

  ["test-capacity-full-goes-to-drop"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.spawn_bang(w, "tree", {x = 5, y = 4})
    local t = world.world_get(w, 2, "task")
    t.kind = "gather"
    t.phase = "gathering"
    t.target = 3
    t.tx = 5
    t.ty = 4
    local cargo = world.world_get(w, 2, "carry")
    cargo.amount = 10
    cargo.resource = "wood"
    local node = world.world_get(w, 3, "node")
    node.amount = 100
    local gather = require("src.systems.gather")
    gather.gather_system(w)
    local t2 = world.world_get(w, 2, "task")
    luaunit.assertEquals(t2.phase, "to-drop")
  end,

  ["test-gather-system-function"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.spawn_bang(w, "tree", {x = 5, y = 4})
    local t = world.world_get(w, 2, "task")
    t.kind = "gather"
    t.phase = "gathering"
    t.target = 3
    t.tx = 5
    t.ty = 4
    local node = world.world_get(w, 3, "node")
    node.amount = 100
    local gather = require("src.systems.gather")
    gather.gather_system(w)
    local cargo = world.world_get(w, 2, "carry")
    luaunit.assertTrue(cargo.amount > 0)
  end,
}
