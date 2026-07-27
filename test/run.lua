-- test/run.lua --- Load all test modules and run via luaunit.
local luaunit = require("luaunit")

local tests = {
  "test.world_test",
  "test.rng_test",
  "test.iso_test",
  "test.orders_test",
  "test.lockstep_test",
  "test.age_test",
  "test.combat_test",
  "test.determinism_test",
  "test.gather_test",
  "test.movement_test",
  "test.production_test",
  "test.ai_test",
  "test.hud_test",
}

for _, mod in ipairs(tests) do
  local t = require(mod)
  for name, func in pairs(t) do
    _G[name] = func
  end
end

os.exit(luaunit.LuaUnit.run())
