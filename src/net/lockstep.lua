-- aurelius.net.lockstep --- deterministic lockstep simulation coordinator.
-- Both players run the full simulation; exchange commands each tick.

local world = require("src.world")
local orders = require("src.orders")
local sim = require("src.sim")

local tick_rate = 15  -- Hz, matching AoE2's pace
local pending_commands = {}
local remote_commands = {}
local connected = false
local is_host = false

local function set_tick_rate(hz)
  tick_rate = hz
end

local function add_local_command(cmd)
  table.insert(pending_commands, cmd)
end

local function receive_remote_commands(cmds)
  remote_commands = cmds
end

-- Called each love.update; returns true if tick advanced
local function maybe_tick(w, dt)
  local tick_duration = 1 / tick_rate
  -- Accumulate time and tick when ready
  if not w._net_timer then
    w._net_timer = 0
  end
  w._net_timer = w._net_timer + dt
  if w._net_timer >= tick_duration then
    w._net_timer = w._net_timer - tick_duration
    -- Apply local commands
    for _, cmd in ipairs(pending_commands) do
      orders.issue(w, cmd)
    end
    pending_commands = {}
    -- Apply remote commands
    for _, cmd in ipairs(remote_commands) do
      orders.issue(w, cmd)
    end
    remote_commands = {}
    -- Advance simulation
    sim.tick(w)
    return true
  end
  return nil
end

local function get_pending_commands()
  return pending_commands
end

local function reset_net()
  pending_commands = {}
  remote_commands = {}
  connected = false
end

return {
  set_tick_rate = set_tick_rate,
  add_local_command = add_local_command,
  receive_remote_commands = receive_remote_commands,
  maybe_tick = maybe_tick,
  get_pending_commands = get_pending_commands,
  reset_net = reset_net,
}
