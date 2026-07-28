-- aurelius.sim --- the fixed-timestep tick loop (ADR-0005).
-- System order is fixed and explicit; that order + seed + command log fully determine the run.

local world = require("src.world")
local orders = require("src.orders")
local production = require("src.systems.production")
local age = require("src.systems.age")
local movement = require("src.systems.movement")
local gather = require("src.systems.gather")
local combat = require("src.systems.combat")
local ai = require("src.ai.scripted")
local win_condition = require("src.systems.win-condition")

-- Controller dispatch (ADR-0015/0016): runs after apply-orders!, calls each
-- faction's controller tick. AI controllers issue orders that apply next tick.
local function controller_dispatch(w)
  for p = 0, w.num_players - 1 do
    local ctrl = world.get_controller(w, p)
    if ctrl and ctrl.tick then
      ctrl.tick(w)
    end
  end
end

-- AI takeover (ADR-0016): replace disconnected player's controller with deterministic AI.
-- Replace player P's controller with an AI takeover controller.
local function take_player(w, p)
  world.set_controller(w, p, ai.make_ai_takeover(p))
end

-- The ordered pipeline
local systems = {}

local function init_systems()
  systems = {
    orders.apply_orders,
    controller_dispatch,
    production.production_system,
    age.age_system,
    movement.movement_system,
    gather.gather_system,
    combat.combat_system
  }
end

local function tick(w)
  -- only tick if no winner yet
  if not win_condition.get_winner() then
    for _, sys in ipairs(systems) do
      sys(w)
    end
    -- check win condition after all systems
    win_condition.check_win(w)
  end
  w.tick = w.tick + 1
  return w
end

local function run(w, n)
  for _ = 1, n do
    tick(w)
  end
  return w
end

local function reset_systems()
  init_systems()
end

-- Initialize on load
init_systems()

return {tick = tick, run = run, systems = systems, reset_systems = reset_systems, take_player = take_player}
