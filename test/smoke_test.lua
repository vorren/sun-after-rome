-- test/smoke_test.lua --- smoke test that loads the game and checks for errors.
-- Run with: love . --smoke-test
-- Exits with code 0 on success, 1 on failure.

local world = require("src.world")
local sim = require("src.sim")

local error_msg = nil

function love.load()
  local ok, err = pcall(function()
    local hud = require("src.render.hud")
    local sprites = require("src.render.sprites")
    local floating_text = require("src.render.floating-text")
    local ui = require("src.render.ui")
    -- Test cursor initialization
    hud.init_cursors()
    -- Initialize UI theme
    ui.init()
    -- Test basic world creation
    local w = world.make_world({width = 24, height = 16, players = 2, seed = 42})
    world.spawn_bang(w, "town-centre", {owner = 0, x = 3, y = 3})
    world.spawn_bang(w, "villager", {owner = 0, x = 4, y = 4})
    -- Test a tick
    sim.tick(w)
    -- Test HUD draw
    hud.draw_hud(w)
    -- Test selection highlight
    hud.draw_selection_highlight(w)
    -- Test floating text
    floating_text.draw_texts(w)
    return true
  end)
  if not ok then
    error_msg = err
    print("SMOKE TEST FAILED: " .. err)
    -- Print stack trace for debugging
    if err and err ~= "" then
      print("Stack trace:")
      print(err)
    end
  end
  -- Quit immediately
  love.event.quit(error_msg and 1 or 0)
end

function love.update(dt)
  return nil
end

function love.draw()
  return nil
end
