-- aurelius.render.hud --- HUD overlay with group selection, command hotkeys, cursor changes.

local world = require("src.world")
local content = require("src.content")
local iso = require("src.render.iso")
local orders = require("src.orders")
local floating_text = require("src.render.floating-text")
local sounds = require("src.audio.sounds")
local log = require("src.log")
local ui = require("src.render.ui")
local command_card = require("src.render.ui.command-card")
local production_queue = require("src.render.ui.production-queue")
local camera = require("src.render.camera")

local selected_eids = {}
local command_mode = nil
local drag_start = nil
local cursor_default = nil
local cursor_pointer = nil
local cursor_crosshair = nil
local cursor_hand = nil

local function init_cursors()
  cursor_default = love.mouse.getSystemCursor("arrow")
  cursor_pointer = love.mouse.getSystemCursor("hand")
  cursor_crosshair = love.mouse.getSystemCursor("crosshair")
  cursor_hand = love.mouse.getSystemCursor("hand")
end

local function set_selection(eid)
  selected_eids = {eid}
end

local function get_selection()
  return selected_eids
end

local function add_to_selection(eid)
  local found = false
  for _, e in ipairs(selected_eids) do
    if e == eid then
      found = true
    end
  end
  if not found then
    table.insert(selected_eids, eid)
  end
end

local function remove_from_selection(eid)
  local i = 1
  while i <= #selected_eids do
    if selected_eids[i] == eid then
      table.remove(selected_eids, i)
    else
      i = i + 1
    end
  end
end

local function set_command_mode(mode)
  command_mode = mode
end

local function get_command_mode()
  return command_mode
end

local function set_drag_start(x, y)
  drag_start = {x = x, y = y}
end

local function get_drag_start()
  return drag_start
end

local function clear_drag_start()
  drag_start = nil
end

local function entity_at_tile(w, tile_x, tile_y)
  local best = nil
  local bd = nil
  for _, pair in ipairs(world.world_query(w, "position")) do
    local eid = pair.eid
    local pos = pair.val
    local d = math.abs(pos.x - tile_x) + math.abs(pos.y - tile_y)
    if bd == nil or d < bd then
      best = eid
      bd = d
    end
  end
  if best and bd <= 2 then
    return best
  end
end

local function entities_in_rect(w, x1, y1, x2, y2)
  local min_x = math.min(x1, x2)
  local max_x = math.max(x1, x2)
  local min_y = math.min(y1, y2)
  local max_y = math.max(y1, y2)
  local result = {}
  for _, pair in ipairs(world.world_query(w, "position")) do
    local eid = pair.eid
    local pos = pair.val
    local owner = world.world_get(w, eid, "owner")
    if owner and owner.player == 0
       and pos.x >= min_x and pos.x <= max_x
       and pos.y >= min_y and pos.y <= max_y then
      table.insert(result, eid)
    end
  end
  return result
end

local function tile_at_screen(screen_x, screen_y)
  local tile_w = 64
  local tile_h = 32
  local offset_x, offset_y = camera.get_offset()
  local raw_tx, raw_ty = iso.to_tile(screen_x - offset_x, screen_y - offset_y, tile_w, tile_h)
  return math.floor(raw_tx + 0.5),
         math.floor(raw_ty + 0.5)
end

local function classify_target(w, eid)
  if eid then
    local kind = world.world_get(w, eid, "kind")
    local owner = world.world_get(w, eid, "owner")
    local node = world.world_get(w, eid, "node")
    if kind then
      if node then
        return "resource"
      elseif owner and owner.player ~= 0 then
        return "enemy"
      elseif owner and kind and owner.player == 0 then
        if content.kind_stat(kind.tag, "damage", 0) > 0 then
          return "unit"
        else
          return "building"
        end
      else
        return "neutral"
      end
    end
  end
end

local function issue_gather(w, eid, target)
  if world.world_get(w, target, "position") then
    orders.issue(w, orders.gather(eid, target))
    floating_text.add_text(w, eid, "Gather")
    sounds.play("gather")
    log.debug("command", "Entity " .. eid .. " gathering from " .. target)
  end
end

local function issue_attack(w, eid, target)
  if world.world_get(w, target, "position") then
    orders.issue(w, orders.attack(eid, target))
    floating_text.add_text(w, eid, "Attack")
    sounds.play("attack")
    log.debug("command", "Entity " .. eid .. " attacking " .. target)
  end
end

local function issue_move(w, eid, tx, ty)
  orders.issue(w, orders.move(eid, tx, ty))
  floating_text.add_text(w, eid, "Move")
  sounds.play("move")
  log.debug("command", "Entity " .. eid .. " moving to " .. tx .. "," .. ty)
end

local function issue_command_to_selected(w, x, y)
  local tile_x, tile_y = tile_at_screen(x, y)
  local target = entity_at_tile(w, tile_x, tile_y)
  for _, eid in ipairs(selected_eids) do
    if command_mode == "gather" then
      if target then
        issue_gather(w, eid, target)
      end
    elseif command_mode == "attack" then
      if target then
        issue_attack(w, eid, target)
      end
    else
      issue_move(w, eid, tile_x, tile_y)
    end
  end
end

local function handle_command_click(x, y, w)
  if #selected_eids > 0 then
    issue_command_to_selected(w, x, y)
    command_mode = nil
  end
end

local function handle_right_click(x, y, w)
  if #selected_eids > 0 then
    local tile_x, tile_y = tile_at_screen(x, y)
    local target = entity_at_tile(w, tile_x, tile_y)
    local target_type = classify_target(w, target)
    for _, eid in ipairs(selected_eids) do
      local kind = world.world_get(w, eid, "kind")
      local producer = world.world_get(w, eid, "producer")
      -- if this is a building with a producer, set rally point
      if producer and kind then
        producer.rally_x = tile_x
        producer.rally_y = tile_y
        log.debug("hud", "Rally point set for " .. tostring(kind.tag) .. " at " .. tile_x .. "," .. tile_y)
      elseif target_type == "resource" then
        issue_gather(w, eid, target)
      elseif target_type == "enemy" then
        issue_attack(w, eid, target)
      else
        issue_move(w, eid, tile_x, tile_y)
      end
    end
  end
end

local function handle_mouse_move(x, y, w)
  if cursor_default then
    local tile_x, tile_y = tile_at_screen(x, y)
    local eid = entity_at_tile(w, tile_x, tile_y)
    local target_type
    if eid then
      target_type = classify_target(w, eid)
    end
    if command_mode then
      love.mouse.setCursor(cursor_crosshair)
    elseif target_type == "resource" then
      love.mouse.setCursor(cursor_hand)
    elseif target_type == "enemy" then
      love.mouse.setCursor(cursor_crosshair)
    elseif eid then
      love.mouse.setCursor(cursor_pointer)
    else
      love.mouse.setCursor(cursor_default)
    end
  end
end

local function draw_selection_highlight(w)
  for _, eid in ipairs(selected_eids) do
    local pos = world.world_get(w, eid, "position")
    local kind = world.world_get(w, eid, "kind")
    if pos and kind then
      local tile_w = 64
      local tile_h = 32
      local offset_x, offset_y = camera.get_offset()
      local sx, sy = iso.to_screen(pos.x, pos.y, tile_w, tile_h)
      local screen_x = sx + offset_x
      local screen_y = sy + offset_y
      love.graphics.setColor(0.2, 1, 0.2, 0.8)
      love.graphics.setLineWidth(2)
      love.graphics.ellipse("line", screen_x, screen_y, tile_w * 0.6, tile_h * 0.6)
      love.graphics.setLineWidth(1)
      love.graphics.setColor(1, 1, 1, 1)
    end
  end
end

local function draw_drag_rect()
  if drag_start then
    local mx = love.mouse.getX()
    local my = love.mouse.getY()
    love.graphics.setColor(0.2, 1, 0.2, 0.3)
    love.graphics.rectangle("fill",
      math.min(drag_start.x, mx), math.min(drag_start.y, my),
      math.abs(mx - drag_start.x), math.abs(my - drag_start.y))
    love.graphics.setColor(0.2, 1, 0.2, 0.8)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line",
      math.min(drag_start.x, mx), math.min(drag_start.y, my),
      math.abs(mx - drag_start.x), math.abs(my - drag_start.y))
  end
end

local function get_scale()
  -- Get scale factor based on window size (reference: 1280x720).
  local w, h = love.graphics.getDimensions()
  return math.min(w / 1280, h / 720)
end

local function draw_hud(w)
  local s = get_scale()
  local pl = 0
  local wood = world.resource_amount(w, pl, "wood")
  local gold = world.resource_amount(w, pl, "gold")
  local stone = world.resource_amount(w, pl, "stone")
  local age = world.player_age(w, pl)
  local prog = world.age_progress(w, pl)
  local screen_w, screen_h = love.graphics.getDimensions()

  -- Build selection context
  local selection_context = nil
  if #selected_eids > 0 then
    local eid = selected_eids[1]
    local kind = world.world_get(w, eid, "kind")
    local task = world.world_get(w, eid, "task")
    local health = world.world_get(w, eid, "health")
    local stats
    if kind then
      stats = content.kind_stats(kind.tag)
    end
    local max_hp
    if stats then
      max_hp = stats["max-hp"]
    end
    local children = {}
    table.insert(children, {
      type = "label",
      x = 0, y = 0,
      text = "Selected: " .. #selected_eids .. " units",
      font = "lg", color = "gold"
    })
    if kind then
      table.insert(children, {
        type = "label",
        x = 0, y = 20 * s,
        text = "Type: " .. tostring(kind.tag),
        font = "md", color = "brown"
      })
    end
    if task then
      table.insert(children, {
        type = "label",
        x = 0, y = 38 * s,
        text = "Task: " .. tostring(task.kind),
        font = "md", color = "brown-light"
      })
    end
    if health and max_hp then
      table.insert(children, {
        type = "bar",
        x = 0, y = 56 * s,
        w = 280, h = 12 * s,
        value = health.hp, max = max_hp,
        fill = "gold", bg = "brown"
      })
    end
    selection_context = {
      type = "panel",
      x = "left", y = "bottom-110",
      w = 300, h = 100,
      pad = 10 * s,
      children = children
    }
  end

  -- Build command mode hint
  local command_mode_hint = nil
  if command_mode then
    command_mode_hint = {
      type = "panel",
      x = "left", y = "bottom-60",
      w = 300, h = 30 * s,
      pad = 8 * s,
      alpha = 0.9,
      children = {
        {
          type = "label",
          x = 0, y = 0,
          text = string.upper(tostring(command_mode)) .. " - click target",
          font = "md", color = "gold"
        }
      }
    }
  end

  -- Resource bar using UI module
  ui.draw(
    ui.root({},
      -- Empire status strip
      {type = "panel",
       x = "top", y = "left",
       w = 400, h = 50 * s,
       dir = "horiz", gap = 12 * s, pad = 8 * s,
       alpha = 0.85,
       children = {
         {type = "label",
          x = 0, y = 0,
          text = "Age " .. tostring(age),
          font = "md", color = "gold"},
         {type = "label",
          x = 0, y = 0,
          text = "Wood: " .. wood,
          font = "md", color = "sage"},
         {type = "label",
          x = 0, y = 0,
          text = "Gold: " .. gold,
          font = "md", color = "gold"},
         {type = "label",
          x = 0, y = 0,
          text = "Stone: " .. stone,
          font = "md", color = "brown-light"}
       }},
      -- Selection context
      selection_context,
      -- Command card
      command_card.build(w, selected_eids,
        function(cmd)
          if cmd.train then
            log.info("command-card", "Training " .. cmd.train)
          else
            set_command_mode(cmd.mode)
            log.debug("command-card", "Command mode: " .. cmd.mode)
          end
        end),
      -- Production queue
      production_queue.build(w, selected_eids),
      -- Command mode hint
      command_mode_hint
    ))

  -- Age advancement progress
  if prog then
    love.graphics.setColor(0.5, 0.8, 1)
    love.graphics.print("Advancing... " .. prog .. " ticks left", 10 * s, 70 * s)
  end

  -- Win condition display
  local win_condition = require("src.systems.win-condition")
  local winner = win_condition.get_winner()
  if winner then
    love.graphics.setColor(0.96, 0.90, 0.78)
    love.graphics.rectangle("fill", (screen_w - 400) / 2, (screen_h - 100) / 2, 400, 100)
    love.graphics.setColor(0.24, 0.17, 0.12)
    love.graphics.printf("Player " .. (winner + 1) .. " Wins!",
      (screen_w - 400) / 2, (screen_h - 100) / 2 + 20, 400, "center")
    love.graphics.printf("Press F5 to restart",
      (screen_w - 400) / 2, (screen_h - 100) / 2 + 50, 400, "center")
  end
end

local function handle_click(x, y, w, button, shift)
  if button == 1 then
    if command_mode then
      handle_command_click(x, y, w)
    else
      local tile_x, tile_y = tile_at_screen(x, y)
      local eid = entity_at_tile(w, tile_x, tile_y)
      if shift then
        if eid then
          if #selected_eids > 0 then
            remove_from_selection(eid)
          else
            add_to_selection(eid)
          end
        end
      else
        if eid then
          set_selection(eid)
        else
          selected_eids = {}
        end
      end
    end
  elseif button == 2 then
    handle_right_click(x, y, w)
  end
end

return {
  ["draw-hud"] = draw_hud,
  ["handle-click"] = handle_click,
  ["set-selection!"] = set_selection,
  ["get-selection"] = get_selection,
  ["draw-selection-highlight"] = draw_selection_highlight,
  ["set-command-mode"] = set_command_mode,
  ["get-command-mode"] = get_command_mode,
  ["set-drag-start"] = set_drag_start,
  ["get-drag-start"] = get_drag_start,
  ["clear-drag-start"] = clear_drag_start,
  ["entities-in-rect"] = entities_in_rect,
  ["add-to-selection"] = add_to_selection,
  ["remove-from-selection"] = remove_from_selection,
  ["draw-drag-rect"] = draw_drag_rect,
  ["init-cursors"] = init_cursors,
  ["handle-mouse-move"] = handle_mouse_move
}
