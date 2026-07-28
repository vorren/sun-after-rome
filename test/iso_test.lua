-- Test: Isometric coordinate transforms
local luaunit = require("luaunit")
local iso = require("src.render.iso")

return {
  ["test-to-screen-and-back"] = function()
    local tile_w = 64
    local tile_h = 32
    -- Round-trip should preserve coordinates
    for x = 0, 10 do
      for y = 0, 10 do
        local sx, sy = iso.to_screen(x, y, tile_w, tile_h)
        local tx, ty = iso.to_tile(sx, sy, tile_w, tile_h)
        -- Allow small floating point error
        luaunit.assertAlmostEquals(tx, x, 0.001)
        luaunit.assertAlmostEquals(ty, y, 0.001)
      end
    end
  end,

  ["test-depth-key-ordering"] = function()
    -- Entities further back should have lower depth keys
    local k1 = iso.depth_key(0, 0)
    local k2 = iso.depth_key(1, 0)
    local k3 = iso.depth_key(0, 1)
    luaunit.assertTrue(k1 < k2)
    luaunit.assertTrue(k1 < k3)
  end,
}
