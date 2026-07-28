-- aurelius.init --- LÖVE callbacks: love.load, love.update, love.draw, etc.
-- This is the main game module.

local world = require("src.world")
local sim = require("src.sim")
local orders = require("src.orders")
local sprites = require("src.render.sprites")
local hud = require("src.render.hud")
local map = require("src.render.map")
local floating_text = require("src.render.floating-text")
local ai = require("src.ai.scripted")
local interpolation = require("src.render.interpolation")
local font = require("src.render.font")
local log = require("src.log")
local minimap = require("src.render.ui.minimap")
local win_condition = require("src.systems.win-condition")

local game_world = nil
local terrain = nil
local music = nil

local function spawn_initial_entities(w)
  world.spawn(w, "town-centre", {owner = 0, x = 3, y = 3})
  world.spawn(w, "town-centre", {owner = 1, x = 20, y = 12})
  world.spawn(w, "barracks", {owner = 0, x = 5, y = 3})
  world.spawn(w, "barracks", {owner = 1, x = 18, y = 12})
  world.spawn(w, "villager", {owner = 0, x = 4, y = 4})
  world.spawn(w, "villager", {owner = 0, x = 4, y = 5})
  world.spawn(w, "villager", {owner = 1, x = 19, y = 11})
  world.spawn(w, "tree", {x = 8, y = 6})
  world.spawn(w, "tree", {x = 9, y = 6})
  world.spawn(w, "tree", {x = 8, y = 7})
  world.spawn(w, "gold-mine", {x = 12, y = 8})
  world.spawn(w, "stone-mine", {x = 15, y = 10})
end

local function setup_world()
  log.info("init", "Setting up game world")
  game_world = world.make_world({width = 24, height = 16, players = 2, seed = 42})
  spawn_initial_entities(game_world)
  world.set_controller(game_world, 1, ai.make_ai_controller(1))
  terrain = map.init_map(game_world, 42)
  floating_text.clear_texts()
  interpolation.clear()
  win_condition.reset_winner()
  win_condition.start_game()
  log.info("init", "World ready")
end

function love.load()
  log.set_level("info")
  log.info("init", "Loading Sun After Rome")
  setup_world()
  hud.init_cursors()
  font.load_fonts()
  minimap.init()
  local ok, source = pcall(love.audio.newSource, "assets/music/sar.ogg", "stream")
  if ok then
    music = source
    music:setLooping(true)
    music:setVolume(0.3)
    love.audio.play(music)
    log.info("audio", "Music loaded")
  else
    log.warn("audio", "Music file not found")
  end
  local ok, repl = pcall(require, "lib.stdio")
  if ok then
    repl.init_env(game_world)
    repl.start()
    log.info("repl", "REPL ready")
  end
  log.info("init", "Game loaded successfully")
end

local accumulator = 0
local tick_dt = 1 / 15

function love.update(raw_dt)
  local dt = raw_dt
  if dt > 0.1 then
    dt = 0.1
  end
  accumulator = accumulator + dt
  -- Save positions ONCE before any ticks run
  interpolation.save_positions(game_world)
  while accumulator >= tick_dt do
    accumulator = accumulator - tick_dt
    sim.tick(game_world)
  end
  interpolation.set_alpha(accumulator / tick_dt)
  floating_text.update_texts(dt)
  local ok, repl = pcall(require, "lib.stdio")
  if ok then repl.poll() end
end

function love.draw()
  if terrain then
    map.draw_terrain(terrain, game_world)
  end
  sprites.draw_world(game_world)
  hud.draw_selection_highlight(game_world)
  hud.draw_drag_rect()
  floating_text.draw_texts(game_world)
  hud.draw_hud(game_world)
  minimap.draw(game_world)
end

function love.keypressed(key)
  if key == "f5" then
    setup_world()
    hud.init_cursors()
    minimap.init()
    local ok, repl = pcall(require, "lib.stdio")
    if ok then repl.init_env(game_world) end
    print("World reset.")
  elseif key == "escape" then
    hud.set_command_mode(nil)
    love.event.quit()
  elseif key == "f2" then
    minimap.toggle()
  elseif key == "f3" then
    sprites.toggle_grid()
  elseif key == "m" then
    hud.set_command_mode("move")
  elseif key == "g" then
    hud.set_command_mode("gather")
  elseif key == "a" then
    hud.set_command_mode("attack")
  elseif key == "1" then
    orders.issue(game_world, orders.train(2, "villager"))
  elseif key == "2" then
    orders.issue(game_world, orders.train(3, "knight"))
  elseif key == "3" then
    orders.issue(game_world, orders.train(3, "pikeman"))
  elseif key == "4" then
    orders.issue(game_world, orders.train(3, "archer"))
  elseif key == "space" then
    orders.issue(game_world, orders.advance_age(0))
  elseif key == "b" then
    orders.issue(game_world, orders.advance_age(1))
  end
end

function love.mousepressed(x, y, button, shift)
  -- check minimap click first (scrolls camera if clicked)
  local screen_w, screen_h = love.graphics.getDimensions()
  minimap.handle_click(x, y, game_world, screen_w, screen_h)
  -- then handle HUD clicks
  hud.handle_click(x, y, game_world, button, shift)
  if (button == 1) and (not hud.get_command_mode()) then
    hud.set_drag_start(x, y)
  end
end

function love.mousereleased(x, y, button)
  if (button == 1) and hud.get_drag_start() then
    local ds = hud.get_drag_start()
    if (x ~= ds.x) or (y ~= ds.y) then
      local entities = hud.entities_in_rect(game_world, ds.x, ds.y, x, y)
      if #entities > 0 then
        hud.clear_drag_start()
        for _, eid in ipairs(entities) do
          hud.add_to_selection(eid)
        end
      end
    end
    hud.clear_drag_start()
  end
end

function love.mousemoved(x, y)
  hud.handle_mouse_move(x, y, game_world)
end

function love.focus(focused)
  if music then
    if focused then
      music:play()
    else
      love.audio.pause(music)
    end
  end
end

local function get_world()
  return game_world
end

local function get_terrain()
  return terrain
end

return {get_world = get_world, get_terrain = get_terrain}
