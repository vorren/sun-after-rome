-- aurelius.components --- component constructors (plain tables).
-- ADR-0003: entities are bare integer ids; components are plain data.

local function make_position(x, y)
  return {x = x, y = y}
end

local function make_owner(player)
  return {player = player}
end

local function make_kind(tag)
  return {tag = tag}
end

local function make_health(hp)
  return {hp = hp}
end

local function make_carry(resource, amount)
  return {resource = resource, amount = amount}
end

local function make_node(resource, amount)
  return {resource = resource, amount = amount}
end

local function make_cooldown(ticks)
  return {ticks = ticks}
end

local function make_producer(queue, progress, rally_x, rally_y)
  return {queue = queue, progress = progress, rally_x = rally_x, rally_y = rally_y}
end

local function make_task(kind, target, tx, ty, phase)
  return {kind = kind, target = target, tx = tx, ty = ty, phase = phase}
end

local function make_task_queue()
  return {pending = {}}
end

return {
  make_position = make_position,
  make_owner = make_owner,
  make_kind = make_kind,
  make_health = make_health,
  make_carry = make_carry,
  make_node = make_node,
  make_cooldown = make_cooldown,
  make_producer = make_producer,
  make_task = make_task,
  make_task_queue = make_task_queue
}
