-- Test: HUD module
local luaunit = require("luaunit")

return {
  ["test-hud-compiles-correctly"] = function()
    local hud = require("src.render.hud")
    luaunit.assertNotNil(hud.draw_hud)
    luaunit.assertNotNil(hud.handle_click)
    luaunit.assertNotNil(hud.set_selection_bang)
    luaunit.assertNotNil(hud.get_selection)
    luaunit.assertNotNil(hud.draw_selection_highlight)
  end,

  ["test-hud-uses-correct-love-api"] = function()
    local f = io.open("src/render/hud.fnl", "r")
    local content = f:read("*a")
    f:close()
    luaunit.assertNotNil(string.find(content, "love%.graphics%.setLineWidth"))
    luaunit.assertNil(string.find(content, "love%.graphics%.set%-line%-width"))
  end,
}
