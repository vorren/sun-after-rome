-- test/test-ui.lua --- Tests for the UI module.

local luaunit = require("luaunit")
local theme = require("src.render.ui.theme")

return {
  ["test-hex-to-rgb-converts-hex"] = function()
    local result = theme.hex_to_rgb("#F5E6C8")
    luaunit.assertNotNil(result)
    luaunit.assertEquals(type(result), "table")
    luaunit.assertEquals(#result, 3)
  end,

  ["test-resolve-color-accepts-hex"] = function()
    local result = theme.resolve_color("#D4A017")
    luaunit.assertNotNil(result)
    luaunit.assertEquals(type(result), "table")
  end,

  ["test-resolve-color-passes-through-tables"] = function()
    local input = {0.5, 0.5, 0.5}
    local result = theme.resolve_color(input)
    luaunit.assertEquals(result, input)
  end,

  ["test-make-theme-creates-a-theme"] = function()
    local t = theme.make_theme({})
    luaunit.assertNotNil(t)
    luaunit.assertNotNil(t.parchment)
    luaunit.assertNotNil(t.terracotta)
    luaunit.assertNotNil(t.gold)
  end,

  ["test-make-theme-accepts-overrides"] = function()
    local t = theme.make_theme({parchment = "#FFFFFF"})
    luaunit.assertNotNil(t)
    luaunit.assertNotNil(t.parchment)
  end,

  ["test-hex-to-rgb-black"] = function()
    local result = theme.hex_to_rgb("#000000")
    luaunit.assertEquals(result[1], 0)
    luaunit.assertEquals(result[2], 0)
    luaunit.assertEquals(result[3], 0)
  end,

  ["test-hex-to-rgb-white"] = function()
    local result = theme.hex_to_rgb("#FFFFFF")
    luaunit.assertEquals(result[1], 1)
    luaunit.assertEquals(result[2], 1)
    luaunit.assertEquals(result[3], 1)
  end,
}
