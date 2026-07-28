-- Test: Combat system
local luaunit = require("luaunit")
local world = require("src.world")
local sim = require("src.sim")
local combat = require("src.systems.combat")

return {
  ["test-attack-damage-deterministic"] = function()
    local w1 = world.make_world({seed = 42})
    local w2 = world.make_world({seed = 42})
    for _, w in ipairs({w1, w2}) do
      world.spawn_bang(w, "knight", {owner = 0, x = 5, y = 5})
      world.spawn_bang(w, "archer", {owner = 1, x = 6, y = 5})
    end
    -- Entity 1 = knight, entity 2 = archer
    local d1 = combat.attack_damage(w1, 1, 2)
    local d2 = combat.attack_damage(w2, 1, 2)
    luaunit.assertEquals(d1, d2)
  end,

  ["test-knight-beats-archer"] = function()
    local w = world.make_world({seed = 42})
    local orders = require("src.orders")
    world.spawn_bang(w, "knight", {owner = 0, x = 5, y = 5})
    world.spawn_bang(w, "archer", {owner = 1, x = 6, y = 5})
    -- Entity 1 = knight, entity 2 = archer
    orders.issue_bang(w, orders.attack(1, 2))
    -- Attack for 60 ticks
    for _ = 1, 60 do
      sim.tick_bang(w)
    end
    -- Archer should be dead
    luaunit.assertFalse(world.world_has_q(w, 2, "health"))
  end,

  ["test-pikeman-bonus-vs-cavalry"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "pikeman", {owner = 0, x = 5, y = 5})
    world.spawn_bang(w, "knight", {owner = 1, x = 6, y = 5})
    world.spawn_bang(w, "archer", {owner = 1, x = 6, y = 6})
    -- Entity 1 = pikeman, 2 = knight, 3 = archer
    -- Pike vs knight should do more damage than pike vs archer
    local d_pk = combat.attack_damage(w, 1, 2)
    local d_pa = combat.attack_damage(w, 1, 3)
    luaunit.assertTrue(d_pk > d_pa)
  end,
}
