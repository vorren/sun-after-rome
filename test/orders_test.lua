-- Test: Orders
local luaunit = require("luaunit")
local world = require("src.world")
local orders = require("src.orders")

return {
  ["test-issue-and-apply"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "tree", {x = 5, y = 4})
    -- Issue a move command
    orders.issue_bang(w, orders.move(2, 10, 10))
    luaunit.assertEquals(#w.orders, 1)
    -- Apply orders
    orders.apply_orders_bang(w)
    luaunit.assertEquals(#w.orders, 0)
    luaunit.assertEquals(#w.log, 1)
  end,

  ["test-commands-are-data"] = function()
    local cmd = orders.move(1, 5, 5)
    luaunit.assertEquals(cmd.tag, "move")
    luaunit.assertEquals(cmd.eid, 1)
    luaunit.assertEquals(cmd.tx, 5)
    luaunit.assertEquals(cmd.ty, 5)
  end,
}
