local luaunit = require("luaunit")
local theme = require("src.render.ui.theme")
local function _1_()
  local result = theme["hex-to-rgb"]("#F5E6C8")
  luaunit.assertNotNil(result)
  luaunit.assertEquals(type(result), "table")
  return luaunit.assertEquals(#result, 3)
end
local function _2_()
  local result = theme["resolve-color"]("#D4A017")
  luaunit.assertNotNil(result)
  return luaunit.assertEquals(type(result), "table")
end
local function _3_()
  local input = {0.5, 0.5, 0.5}
  local result = theme["resolve-color"](input)
  return luaunit.assertEquals(result, input)
end
local function _4_()
  local t = theme["make-theme"]({})
  luaunit.assertNotNil(t)
  luaunit.assertNotNil(t.parchment)
  luaunit.assertNotNil(t.terracotta)
  return luaunit.assertNotNil(t.gold)
end
local function _5_()
  local t = theme["make-theme"]({parchment = "#FFFFFF"})
  luaunit.assertNotNil(t)
  return luaunit.assertNotNil(t.parchment)
end
local function _6_()
  local result = theme["hex-to-rgb"]("#000000")
  luaunit.assertEquals(result[1], 0)
  luaunit.assertEquals(result[2], 0)
  return luaunit.assertEquals(result[3], 0)
end
local function _7_()
  local result = theme["hex-to-rgb"]("#FFFFFF")
  luaunit.assertEquals(result[1], 1)
  luaunit.assertEquals(result[2], 1)
  return luaunit.assertEquals(result[3], 1)
end
return {["test-hex-to-rgb-converts-hex"] = _1_, ["test-resolve-color-accepts-hex"] = _2_, ["test-resolve-color-passes-through-tables"] = _3_, ["test-make-theme-creates-a-theme"] = _4_, ["test-make-theme-accepts-overrides"] = _5_, ["test-hex-to-rgb-black"] = _6_, ["test-hex-to-rgb-white"] = _7_}
