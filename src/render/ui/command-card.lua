-- aurelius.render.ui.command-card --- clickable action buttons for selected units.
-- Shows Move, Gather, Attack for villagers; Move, Attack for military; Train for buildings.

local world = require("src.world")
local content = require("src.content")
local log = require("src.log")

local function unit_commands(kind_tag)
  -- Return available commands for a unit type.
  if kind_tag == "villager" then
    return {
      {id = "move", label = "Move", mode = "move"},
      {id = "gather", label = "Gather", mode = "gather"},
      {id = "attack", label = "Attack", mode = "attack"}
    }
  else
    -- military units
    return {
      {id = "move", label = "Move", mode = "move"},
      {id = "attack", label = "Attack", mode = "attack"}
    }
  end
end

local function building_commands(kind_tag)
  -- Return available commands for a building type.
  local trains = content.producer_trains(kind_tag)
  if #trains > 0 then
    local cmds = {}
    for _, unit_tag in ipairs(trains) do
      table.insert(cmds, {
        id = "train-" .. unit_tag,
        label = "Train " .. string.upper(unit_tag),
        train = unit_tag
      })
    end
    return cmds
  end
end

local function build(w, selected_eids, on_command)
  -- Build command card UI tree for selected entities.
  -- on-command: function(cmd) called when a command is clicked.
  if #selected_eids > 0 then
    local eid = selected_eids[1]
    local kind = world.world_get(w, eid, "kind")
    if kind then
      local commands
      if content.kinds[kind.tag] then
        if content.kinds[kind.tag].trains then
          commands = building_commands(kind.tag)
        else
          commands = unit_commands(kind.tag)
        end
      else
        commands = {}
      end
      local buttons = {}
      for _, cmd in ipairs(commands) do
        table.insert(buttons, {
          type = "button",
          x = 0, y = 0,
          w = 80, h = 30,
          text = cmd.label,
          font = "sm",
          ["on-click"] = function(_)
            log.debug("command-card", "Clicked: " .. cmd.label)
            on_command(cmd)
          end
        })
      end
      if #buttons > 0 then
        return {
          type = "panel",
          x = "right-170", y = "bottom-110",
          w = (#buttons * 84) + 8, h = 40,
          dir = "horiz", gap = 4, pad = 4,
          children = buttons
        }
      end
    end
  end
end

return {
  ["build"] = build,
  ["unit-commands"] = unit_commands,
  unit_commands = unit_commands,
  ["building-commands"] = building_commands,
  building_commands = building_commands
}
