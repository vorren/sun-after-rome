-- aurelius.systems.production --- buildings train queued units.
-- Cost was already paid when the 'train' command was enqueued (ADR-0009).

local world = require("src.world")
local content = require("src.content")
local orders = require("src.orders")

local function production_system(w)
  for _, pair in ipairs(world.world_query(w, "producer")) do
    local prod = pair.eid
    local p = pair.val
    if #p.queue > 0 then
      local tag = p.queue[1]
      local prog = 1 + p.progress
      if prog >= content.train_time(tag) then
        local pos = world.world_get(w, prod, "position")
        local own = world.world_get(w, prod, "owner")
        -- use rally point if set, otherwise spawn near building
        local spawn_x
        if p.rally_x then
          spawn_x = p.rally_x
        else
          spawn_x = math.min(w.width - 1, 1 + pos.x)
        end
        local spawn_y
        if p.rally_y then
          spawn_y = p.rally_y
        else
          spawn_y = pos.y
        end
        local eid = world.spawn(w, tag, {
          owner = own and own.player,
          x = spawn_x,
          y = spawn_y
        })
        -- if rally point is set and unit isn't already there, order it to move
        if p.rally_x and p.rally_y
            and (spawn_x ~= p.rally_x
              or spawn_y ~= p.rally_y) then
          orders.issue(w, orders.move(eid, p.rally_x, p.rally_y))
        end
        table.remove(p.queue, 1)
        p.progress = 0
      else
        p.progress = prog
      end
    end
  end
end

return {production_system = production_system}
