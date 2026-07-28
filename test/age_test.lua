-- Test: Age advancement
local luaunit = require("luaunit")
local world = require("src.world")
local content = require("src.content")
local sim = require("src.sim")
local orders = require("src.orders")

return {
  ["test-age-advancement"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    luaunit.assertEquals(world.player_age(w, 0), 1)
    world.set_age_progress_bang(w, 0, content.age_time(2))
    for _ = 1, content.age_time(2) do
      w.tick = w.tick + 1
      local left = world.age_progress(w, 0)
      if left then
        world.set_age_progress_bang(w, 0, left - 1)
        if world.age_progress(w, 0) <= 0 then
          world.set_player_age_bang(w, 0, 2)
          world.set_age_progress_bang(w, 0, nil)
        end
      end
    end
    luaunit.assertEquals(world.player_age(w, 0), 2)
  end,

  ["test-cost-check"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    luaunit.assertEquals(world.player_age(w, 0), 1)
    local before = world.resource_amount(w, 0, "wood")
    orders.issue_bang(w, orders.advance_age(0))
    sim.tick_bang(w)
    local after = world.resource_amount(w, 0, "wood")
    luaunit.assertEquals(after, before)
  end,

  ["test-max-age-cap"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.add_resource_bang(w, 0, "wood", 5000)
    world.add_resource_bang(w, 0, "stone", 5000)
    world.add_resource_bang(w, 0, "gold", 5000)
    world.set_player_age_bang(w, 0, content.max_age())
    local before = world.resource_amount(w, 0, "wood")
    orders.issue_bang(w, orders.advance_age(0))
    sim.tick_bang(w)
    local after = world.resource_amount(w, 0, "wood")
    luaunit.assertEquals(after, before)
  end,

  ["test-age-bonuses-apply"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.set_player_age_bang(w, 0, 1)
    local hp1 = world.effective_max_hp(w, 2)
    world.set_player_age_bang(w, 0, 2)
    local hp2 = world.effective_max_hp(w, 2)
    luaunit.assertTrue(hp2 > hp1)
  end,

  ["test-advancement-countdown"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    orders.issue_bang(w, orders.advance_age(0))
    sim.tick_bang(w)
    local left = world.age_progress(w, 0)
    luaunit.assertNotNil(left)
    luaunit.assertTrue(left > 0)
  end,
}
