-- Test: RNG determinism
local luaunit = require("luaunit")
local rng = require("src.rng")

return {
  ["test-rng-determinism"] = function()
    local r1 = rng.make_rng(42)
    local r2 = rng.make_rng(42)
    for _ = 1, 100 do
      luaunit.assertEquals(rng.rng_next_bang(r1), rng.rng_next_bang(r2))
    end
  end,

  ["test-rng-different-seeds-diverge"] = function()
    local r1 = rng.make_rng(1)
    local r2 = rng.make_rng(999)
    local same = true
    for _ = 1, 10 do
      if rng.rng_next_bang(r1) ~= rng.rng_next_bang(r2) then
        same = false
      end
    end
    luaunit.assertFalse(same)
  end,

  ["test-rng-below-range"] = function()
    local r = rng.make_rng(42)
    for _ = 1, 100 do
      local v = rng.rng_below_bang(r, 10)
      luaunit.assertTrue(v >= 0)
      luaunit.assertTrue(v < 10)
    end
  end,

  ["test-rng-range"] = function()
    local r = rng.make_rng(42)
    for _ = 1, 100 do
      local v = rng.rng_range_bang(r, 5, 15)
      luaunit.assertTrue(v >= 5)
      luaunit.assertTrue(v <= 15)
    end
  end,
}
