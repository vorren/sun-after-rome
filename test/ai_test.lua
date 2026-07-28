-- Test: AI controller system
local luaunit = require("luaunit")
local world = require("src.world")
local sim = require("src.sim")
local orders = require("src.orders")
local content = require("src.content")
local ai = require("src.ai.scripted")
local personalities = require("src.ai.personalities")

return {
  ["test-ai-creates-orders"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.add_resource_bang(w, 0, "wood", 200)
    world.add_resource_bang(w, 0, "gold", 200)
    world.add_resource_bang(w, 0, "stone", 200)
    world.set_controller(w, 0, ai.make_ai_controller(0))
    ai.ai_system(w, 0)
    luaunit.assertTrue(#w.orders > 0)
  end,

  ["test-ai-trains-villagers"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    ai.ai_system(w, 0)
    local found_train = false
    for _, o in ipairs(w.orders) do
      if o.tag == "train" and o.unit == "villager" then
        found_train = true
      end
    end
    luaunit.assertTrue(found_train)
  end,

  ["test-ai-does-not-overtrain"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    for _ = 1, 6 do
      world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    end
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    ai.ai_system(w, 0)
    local found_train = false
    for _, o in ipairs(w.orders) do
      if o.tag == "train" and o.unit == "villager" then
        found_train = true
      end
    end
    luaunit.assertFalse(found_train)
  end,

  ["test-ai-advances-age"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    luaunit.assertEquals(world.player_age(w, 0), 1)
    ai.ai_system(w, 0)
    local found_advance = false
    for _, o in ipairs(w.orders) do
      if o.tag == "advance-age" then
        found_advance = true
      end
    end
    luaunit.assertTrue(found_advance)
  end,

  ["test-ai-does-not-advance-if-cannot-afford"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    ai.ai_system(w, 0)
    local found_advance = false
    for _, o in ipairs(w.orders) do
      if o.tag == "advance-age" then
        found_advance = true
      end
    end
    luaunit.assertFalse(found_advance)
  end,

  ["test-ai-attacks-enemy"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "knight", {owner = 0, x = 5, y = 5})
    world.spawn_bang(w, "villager", {owner = 1, x = 10, y = 10})
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    ai.ai_system(w, 0)
    local found_attack = false
    for _, o in ipairs(w.orders) do
      if o.tag == "attack" then
        found_attack = true
      end
    end
    luaunit.assertTrue(found_attack)
  end,

  ["test-ai-deterministic"] = function()
    local w1 = world.make_world({seed = 42})
    local w2 = world.make_world({seed = 42})
    for _, w in ipairs({w1, w2}) do
      world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
      world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
      world.add_resource_bang(w, 0, "wood", 200)
      world.add_resource_bang(w, 0, "gold", 200)
      world.add_resource_bang(w, 0, "stone", 200)
    end
    ai.ai_system(w1, 0)
    ai.ai_system(w2, 0)
    luaunit.assertEquals(#w1.orders, #w2.orders)
    for i = 1, #w1.orders do
      local o1 = w1.orders[i]
      local o2 = w2.orders[i]
      luaunit.assertEquals(o1.tag, o2.tag)
      luaunit.assertEquals(o1.eid, o2.eid)
    end
  end,

  ["test-ai-controller-structure"] = function()
    local ctrl = ai.make_ai_controller(0)
    luaunit.assertEquals(ctrl.type, "ai")
    luaunit.assertEquals(ctrl.faction, 0)
    luaunit.assertNotNil(ctrl.tick)
    luaunit.assertNotNil(ctrl.personality)
  end,

  ["test-faction-entities"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.spawn_bang(w, "town-centre", {owner = 1, x = 20, y = 12})
    local ents = ai.faction_entities(w, 0)
    luaunit.assertEquals(#ents, 2)
    local ents2 = ai.faction_entities(w, 1)
    luaunit.assertEquals(#ents2, 1)
  end,

  ["test-has-building"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    luaunit.assertTrue(ai["has_building?"](w, 0, "town-centre"))
    luaunit.assertFalse(ai["has_building?"](w, 0, "barracks"))
    luaunit.assertFalse(ai["has_building?"](w, 1, "town-centre"))
  end,

  ["test-personality-villager-target"] = function()
    local aggressive = personalities.get_personality("aggressive")
    local defensive = personalities.get_personality("defensive")
    luaunit.assertEquals(aggressive["villager-target"], 6)
    luaunit.assertEquals(defensive["villager-target"], 8)
  end,

  ["test-ai-uses-personality-villager-target"] = function()
    local w = world.make_world({seed = 42})
    local defensive = personalities.get_personality("defensive")
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    for _ = 1, 7 do
      world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    end
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    ai.ai_system(w, 0, defensive)
    local found_train = false
    for _, o in ipairs(w.orders) do
      if o.tag == "train" and o.unit == "villager" then
        found_train = true
      end
    end
    luaunit.assertTrue(found_train)
  end,

  ["test-ai-respects-military-threshold"] = function()
    local w = world.make_world({seed = 42})
    local aggressive = personalities.get_personality("aggressive")
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "barracks", {owner = 0, x = 5, y = 5})
    for _ = 1, 2 do
      world.spawn_bang(w, "knight", {owner = 0, x = 6, y = 6})
    end
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    ai.ai_system(w, 0, aggressive)
    local found_train = false
    for _, o in ipairs(w.orders) do
      if o.tag == "train" and o.unit == "knight" then
        found_train = true
      end
    end
    luaunit.assertTrue(found_train)
  end,

  ["test-ai-does-not-overtrain-military"] = function()
    local w = world.make_world({seed = 42})
    local aggressive = personalities.get_personality("aggressive")
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "barracks", {owner = 0, x = 5, y = 5})
    for _ = 1, 3 do
      world.spawn_bang(w, "knight", {owner = 0, x = 6, y = 6})
    end
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    ai.ai_system(w, 0, aggressive)
    local found_train = false
    for _, o in ipairs(w.orders) do
      if o.tag == "train" and o.unit == "knight" then
        found_train = true
      end
    end
    luaunit.assertFalse(found_train)
  end,

  ["test-ai-respects-attack-when-idle"] = function()
    local w = world.make_world({seed = 42})
    local defensive = personalities.get_personality("defensive")
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "knight", {owner = 0, x = 5, y = 5})
    world.spawn_bang(w, "villager", {owner = 1, x = 10, y = 10})
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    ai.ai_system(w, 0, defensive)
    local found_attack = false
    for _, o in ipairs(w.orders) do
      if o.tag == "attack" then
        found_attack = true
      end
    end
    luaunit.assertFalse(found_attack)
  end,

  ["test-ai-takeover-creates-controller"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    sim.take_player(w, 0)
    local ctrl = world.get_controller(w, 0)
    luaunit.assertEquals(ctrl.type, "ai")
    luaunit.assertNotNil(ctrl.tick)
    luaunit.assertNotNil(ctrl.personality)
  end,

  ["test-ai-takeover-issues-orders"] = function()
    local w = world.make_world({seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    world.add_resource_bang(w, 0, "wood", 500)
    world.add_resource_bang(w, 0, "gold", 500)
    world.add_resource_bang(w, 0, "stone", 500)
    sim.take_player(w, 0)
    sim.tick(w)
    sim.tick(w)
    luaunit.assertTrue(#w.log > 0)
  end,
}
