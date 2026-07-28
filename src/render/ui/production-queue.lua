-- aurelius.render.ui.production-queue --- shows what buildings are training.
-- Displays current unit, progress bar, queue, and resource costs.

local world = require("src.world")
local content = require("src.content")
local log = require("src.log")

local function resource_cost_text(cost)
  -- Format resource cost as a string.
  local parts = {}
  for res, amt in pairs(cost) do
    table.insert(parts, tostring(amt) .. " " .. tostring(res))
  end
  return table.concat(parts, ", ")
end

local function build(w, selected_eids)
  -- Build production queue UI tree for selected building.
  if #selected_eids > 0 then
    local eid = selected_eids[1]
    local kind = world.world_get(w, eid, "kind")
    local producer = world.world_get(w, eid, "producer")
    if kind and producer then
      local tag = kind.tag
      local trains = content.producer_trains(tag)
      if #trains > 0 then
        -- build queue display
        local children = {}
        local queue_len = producer.queue and #producer.queue or 0

        -- current training progress
        if queue_len > 0 then
          local current = producer.queue[1]
          local progress = producer.progress or 0
          local train_time = content.train_time(current)
          local ratio = train_time > 0 and (progress / train_time) or 0
          local cost = content.unit_cost(current)
          local cost_label = nil
          if cost then
            cost_label = {
              type = "label",
              x = 0, y = 38,
              text = "Cost: " .. resource_cost_text(cost),
              font = "sm", color = "brown-light"
            }
          end
          table.insert(children, {
            type = "panel",
            x = 0, y = 0,
            w = 280, h = 60,
            pad = 6,
            children = {
              {
                type = "label",
                x = 0, y = 0,
                text = "Training: " .. string.upper(current),
                font = "md", color = "gold"
              },
              {
                type = "bar",
                x = 0, y = 22,
                w = 260, h = 10,
                value = ratio, max = 1,
                fill = "gold", bg = "brown"
              },
              cost_label
            }
          })
        end

        -- queue items (after current)
        if queue_len > 1 then
          local queue_items = {}
          for i = 2, queue_len do
            local unit = producer.queue[i]
            table.insert(queue_items, {
              type = "label",
              x = 0, y = 0,
              text = "Queued: " .. string.upper(unit),
              font = "sm", color = "brown-light"
            })
          end
          table.insert(children, {
            type = "panel",
            x = 0, y = 0,
            w = 280, h = 18 * (1 + (queue_len - 1)),
            pad = 4,
            children = queue_items
          })
        end

        -- train buttons
        local train_btns = {}
        for _, unit_tag in ipairs(trains) do
          local cost = content.unit_cost(unit_tag)
          local resources = world.resources[0]
          local can_afford = (not cost) or (
            (not cost.wood or ((resources.wood or 0) >= cost.wood)) and
            (not cost.gold or ((resources.gold or 0) >= cost.gold)) and
            (not cost.stone or ((resources.stone or 0) >= cost.stone))
          )
          table.insert(train_btns, {
            type = "button",
            x = 0, y = 0,
            w = 80, h = 24,
            text = string.upper(unit_tag),
            font = "sm",
            disabled = not can_afford,
            ["on-click"] = function(_)
              log.info("production-queue", "Training " .. unit_tag)
              -- TODO: issue train order
            end
          })
        end
        if #train_btns > 0 then
          table.insert(children, {
            type = "panel",
            x = 0, y = 0,
            w = (#train_btns * 84) + 8, h = 30,
            dir = "horiz", gap = 4, pad = 4,
            children = train_btns
          })
        end

        if #children > 0 then
          return {
            type = "panel",
            x = "right-300", y = "bottom-180",
            w = 300, h = 70 + (20 * queue_len),
            pad = 8,
            children = children
          }
        end
      end
    end
  end
end

return {
  ["build"] = build,
  ["resource-cost-text"] = resource_cost_text
}
