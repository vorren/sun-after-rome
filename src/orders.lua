-- aurelius.orders --- commands as data (ADR-0009).
-- Commands are the ONLY input to the simulation.

local world = require("src.world")
local content = require("src.content")

-- Constructors (just data)
local function move(eid, tx, ty)
  return {tag = "move", eid = eid, tx = tx, ty = ty}
end

local function gather(eid, node_id)
  return {tag = "gather", eid = eid, node = node_id}
end

local function attack(eid, tgt)
  return {tag = "attack", eid = eid, target = tgt}
end

local function train(prod_id, tag)
  return {tag = "train", prod = prod_id, unit = tag}
end

local function advance_age(player)
  return {tag = "advance_age", player = player}
end

local function concede(player)
  return {tag = "concede", player = player}
end

-- Queueing
local function issue_bang(w, order)
  table.insert(w.orders, 1, order)
  return order
end

-- Aim a task at a target entity's position
local function aim_at_target(t, w, target)
  t.target = target
  if target then
    local p = world["world-get"](w, target, "position")
    if p then
      t.tx = p.x
      t.ty = p.y
    end
  end
end

-- Apply a single command
local function apply_one(w, order)
  if order.tag == "move" then
    local t = world["world-get"](w, order.eid, "task")
    if t then
      t.kind = "move"
      t.phase = nil
      t.target = nil
      t.tx = order.tx
      t.ty = order.ty
      return true
    end
  elseif order.tag == "gather" then
    local t = world["world-get"](w, order.eid, "task")
    if t and world["world-has?"](w, order.node, "node") then
      t.kind = "gather"
      t.phase = "to-node"
      aim_at_target(t, w, order.node)
      return true
    end
  elseif order.tag == "attack" then
    local t = world["world-get"](w, order.eid, "task")
    if t and world["world-has?"](w, order.target, "health") then
      t.kind = "attack"
      t.phase = nil
      aim_at_target(t, w, order.target)
      return true
    end
  elseif order.tag == "train" then
    local p = world["world-get"](w, order.prod, "producer")
    local o = world["world-get"](w, order.prod, "owner")
    if p and o then
      local tag = world["world-get"](w, order.prod, "kind").tag
      local trains = content["producer-trains"](tag)
      local found = false
      for _, t in ipairs(trains) do
        if t == order.unit then found = true end
      end
      if found and world["pay!"](w, o.player, content["unit-cost"](order.unit)) then
        table.insert(p.queue, order.unit)
        return true
      end
    end
  elseif order.tag == "advance_age" then
    local next_age = 1 + world["player-age"](w, order.player)
    if next_age <= content["max-age"]()
       and world["age-progress"](w, order.player) == nil
       and world["pay!"](w, order.player, content["age-cost"](next_age)) then
      world["set-age-progress!"](w, order.player, content["age-time"](next_age))
      return true
    end
  elseif order.tag == "concede" then
    local win_condition = require("src.systems.win-condition")
    -- conceding player loses — the other player wins
    win_condition["set-winner"](w, (order.player == 0) and 1 or 0)
    return true
  end
  return false
end

-- Drain and apply the whole queue oldest-first, logging each command.
local function apply_orders(w)
  local pending = w.orders
  w.orders = {}
  for _, o in ipairs(pending) do
    apply_one(w, o)
    table.insert(w.log, 1, o)
  end
end

-- Serialization (ADR-0009)
local function orders__log(w) return w.log end
local function log__orders(lst) return lst end

return {
  ["move"] = move,
  ["gather"] = gather,
  ["attack"] = attack,
  ["train"] = train,
  ["advance-age"] = advance_age,
  advance_age = advance_age,
  ["issue!"] = issue_bang,
  issue_bang = issue_bang,
  ["apply-orders!"] = apply_orders,
  ["apply_orders!"] = apply_orders,
  ["orders->log"] = orders__log,
  ["orders>_log"] = orders__log,
  ["log->orders"] = log__orders,
  ["log>_orders"] = log__orders,
}
