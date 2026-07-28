-- Test: Movement system
local luaunit = require("luaunit")
local world = require("src.world")
local sim = require("src.sim")
local orders = require("src.orders")
local components = require("src.components")
local movement = require("src.systems.movement")

return {
  ["test-move-command"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    local t = world.world_get(w, 1, "task")
    t.kind = "move"
    t.tx = 10
    t.ty = 10
    local pos = world.world_get(w, 1, "position")
    sim.tick(w)
    luaunit.assertTrue(pos.x > 4 or pos.y > 4)
  end,

  ["test-speed-scaling"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "villager", {owner = 0, x = 0, y = 0})
    world.spawn_bang(w, "knight", {owner = 0, x = 0, y = 2})
    local t1 = world.world_get(w, 1, "task")
    local t2 = world.world_get(w, 2, "task")
    t1.kind = "move"; t1.tx = 20; t1.ty = 0
    t2.kind = "move"; t2.tx = 20; t2.ty = 2
    sim.tick(w)
    local p1 = world.world_get(w, 1, "position")
    local p2 = world.world_get(w, 2, "position")
    luaunit.assertTrue(p2.x > p1.x)
  end,

  ["test-boundary-check"] = function()
    local w = world.make_world({seed = 42, width = 10, height = 10})
    world.spawn_bang(w, "villager", {owner = 0, x = 9, y = 9})
    local t = world.world_get(w, 1, "task")
    t.kind = "move"
    t.tx = 20
    t.ty = 20
    sim.tick(w)
    local pos = world.world_get(w, 1, "position")
    luaunit.assertTrue(pos.x <= 10)
    luaunit.assertTrue(pos.y <= 10)
  end,

  ["test-idle-at-destination"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "villager", {owner = 0, x = 5, y = 5})
    local t = world.world_get(w, 1, "task")
    t.kind = "move"
    t.tx = 5
    t.ty = 5
    sim.tick(w)
    local t2 = world.world_get(w, 1, "task")
    luaunit.assertEquals(t2.kind, "idle")
  end,

  ["test-units-push-on-collision"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "villager", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 1, x = 5, y = 3})
    local t1 = world.world_get(w, 1, "task")
    local t2 = world.world_get(w, 2, "task")
    t1.kind = "move"; t1.tx = 8; t1.ty = 3
    t2.kind = "move"; t2.tx = 1; t2.ty = 3
    sim.tick(w)
    local p1 = world.world_get(w, 1, "position")
    local p2 = world.world_get(w, 2, "position")
    luaunit.assertTrue(p1.x >= 3)
    luaunit.assertTrue(p2.x <= 5)
  end,

  ["test-movement-system-function"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "villager", {owner = 0, x = 0, y = 0})
    local t = world.world_get(w, 1, "task")
    t.kind = "move"
    t.tx = 3
    t.ty = 3
    movement.movement_system(w)
    local pos = world.world_get(w, 1, "position")
    luaunit.assertTrue(pos.x > 0)
  end,
}
