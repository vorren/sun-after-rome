-- aurelius.render.sprites --- sprite rendering with interpolation.
-- Loads actual sprites for villagers, falls back to colored circles for other units.

local world = require("src.world")
local iso = require("src.render.iso")
local interpolation = require("src.render.interpolation")
local camera = require("src.render.camera")
local sprite_sheet = require("src.render.sprite-sheet")
local animation = require("src.render.animation")
local log = require("src.log")

local tile_w = 64
local tile_h = 32

local unit_colors = {
  villager = {0.2, 0.8, 0.2},
  knight = {0.8, 0.2, 0.2},
  pikeman = {0.2, 0.2, 0.8},
  archer = {0.8, 0.8, 0.2}
}

local building_colors = {
  ["town-centre"] = {0.6, 0.4, 0.2},
  barracks = {0.5, 0.5, 0.5}
}

local node_colors = {
  tree = {0.1, 0.5, 0.1},
  ["gold-mine"] = {0.9, 0.8, 0.1},
  ["stone-mine"] = {0.6, 0.6, 0.6}
}

local grid_visible = true

local entity_animations = {}
local villager_walk_no_wood = nil
local villager_walk_wood = nil

local function load_villager_sprites()
  if not villager_walk_no_wood then
    villager_walk_no_wood = sprite_sheet.load_animation(
      "assets/units/Villager/Male/Woodcutter/Walk/Carrying no Wood",
      "Villagerwalk", 75)
    log.info("sprites", "Loaded villager walk sprites (no wood)")
  end
  if not villager_walk_wood then
    villager_walk_wood = sprite_sheet.load_animation(
      "assets/units/Villager/Male/Woodcutter/Walk/Carrying Wood",
      "Villagerwalk", 75)
    log.info("sprites", "Loaded villager walk sprites (with wood)")
  end
end

local function get_or_create_animation(eid, tag, task)
  if entity_animations[eid] then
    return entity_animations[eid]
  end
  local sprites = nil
  if task and tag == "villager" and (task.kind == "gather" or task.kind == "move") then
    if task and task.target then
      sprites = villager_walk_wood
    else
      sprites = villager_walk_no_wood
    end
  end
  local anim = nil
  if sprites then
    anim = animation.make_animation(sprites, 15, true)
  end
  if anim then
    entity_animations[eid] = anim
  end
  return anim
end

local function entity_direction(w, eid)
  local task = world.world_get(w, eid, "task")
  local pos = world.world_get(w, eid, "position")
  if not task or task.kind ~= "move" or not task.tx or not task.ty then
    return 0
  end
  local dx = task.tx - (pos and pos.x or 0)
  local dy = task.ty - (pos and pos.y or 0)
  if math.abs(dx) <= 0.1 and math.abs(dy) <= 0.1 then
    return 0
  end
  local angle = math.atan2(dy, dx)
  if angle <= -2.4 then
    return 0
  elseif angle <= -0.7 then
    return 1
  elseif angle <= 0 then
    return 2
  elseif angle <= 0.7 then
    return 3
  else
    return 4
  end
end

local function toggle_grid()
  grid_visible = not grid_visible
end

local function get_color(tag)
  return unit_colors[tag]
    or building_colors[tag]
    or node_colors[tag]
    or {0.5, 0.5, 0.5}
end

local function health_bar_color(ratio)
  if ratio >= 0.6 then
    return {0.2, 0.8, 0.2}
  elseif ratio >= 0.3 then
    return {0.9, 0.9, 0.2}
  else
    return {0.9, 0.2, 0.2}
  end
end

local function draw_health_bar(w, eid, sx, sy)
  local health = world.world_get(w, eid, "health")
  local kind = world.world_get(w, eid, "kind")
  if health and kind then
    local max_hp = world.effective_max_hp(w, eid)
    local ratio = health.hp / max_hp
    if ratio < 1 then
      local bar_w = 24
      local bar_h = 4
      local bar_x = sx - bar_w / 2
      local bar_y = sy - 20
      local fill_w = bar_w * ratio
      local color = health_bar_color(ratio)
      love.graphics.setColor(0.2, 0.15, 0.1)
      love.graphics.rectangle("fill", bar_x, bar_y, bar_w, bar_h)
      love.graphics.setColor(color[1], color[2], color[3])
      love.graphics.rectangle("fill", bar_x, bar_y, fill_w, bar_h)
    end
  end
end

local function draw_idle_indicator(w, eid, sx, sy)
  local task = world.world_get(w, eid, "task")
  local owner = world.world_get(w, eid, "owner")
  if task and task.kind == "idle" and owner and owner.player == 0 then
    local flash = math.floor((w.tick or 0) / 10)
    local alpha_val
    if flash % 2 == 0 then
      alpha_val = 0.8
    else
      alpha_val = 0.3
    end
    love.graphics.setColor(1, 0.8, 0, alpha_val)
    love.graphics.circle("fill", sx, sy - 20, 4)
  end
end

local function draw_rally_point(w, eid)
  local producer = world.world_get(w, eid, "producer")
  local pos = world.world_get(w, eid, "position")
  if producer and producer.rally_x and producer.rally_y and pos then
    local offset_x, offset_y = camera.get_offset()
    local raw_sx, raw_sy = iso.to_screen(producer.rally_x, producer.rally_y, tile_w, tile_h)
    local sx = raw_sx + offset_x
    local sy = raw_sy + offset_y
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(sx, sy, sy - 20)
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.rectangle("fill", sx, sy - 20, 10, 8)
    love.graphics.setLineWidth(1)
  end
end

local function draw_entity(w, eid)
  local kind = world.world_get(w, eid, "kind")
  local pos = interpolation.interpolated_pos(w, eid)
  if kind and pos then
    local tag = kind.tag
    local raw_sx, raw_sy = iso.to_screen(pos.x, pos.y, tile_w, tile_h)
    local offset_x, offset_y = camera.get_offset()
    local sx = raw_sx + offset_x
    local sy = raw_sy + offset_y
    local task = world.world_get(w, eid, "task")
    local anim = get_or_create_animation(eid, tag, task)
    if anim then
      animation.update(anim, 1 / 60)
      local dir = entity_direction(w, eid)
      local sprite = animation.get_sprite(anim, dir)
      if sprite and sprite.image then
        love.graphics.setColor(1, 1, 1)
        if sprite.mirror then
          love.graphics.draw(sprite.image, sx + 32, sy, 0, -1, 1, 32, 0)
        else
          love.graphics.draw(sprite.image, sx - 32, sy, 0, 1, 1, 0, 0)
        end
      end
    else
      local color = get_color(tag)
      if building_colors[tag] then
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill", sx - 24, sy - 32, 48, 64)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", sx - 24, sy - 32, 48, 64)
      else
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.circle("fill", sx, sy - 8, 8)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("line", sx, sy - 8, 8)
      end
    end
    draw_health_bar(w, eid, sx, sy)
    draw_idle_indicator(w, eid, sx, sy)
    if building_colors[tag] then
      draw_rally_point(w, eid)
    end
  end
end

local function draw_isometric_grid(w)
  if grid_visible then
    local offset_x, offset_y = camera.get_offset()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
    for x = 0, w.width - 1 do
      for y = 0, w.height - 1 do
        local raw_sx, raw_sy = iso.to_screen(x, y, tile_w, tile_h)
        local sx = raw_sx + offset_x
        local sy = raw_sy + offset_y
        love.graphics.line(
          sx, sy - tile_h / 2,
          sx + tile_w / 2, sy,
          sx, sy + tile_h / 2,
          sx - tile_w / 2, sy,
          sx, sy - tile_h / 2)
      end
    end
  end
end

local function draw_world(w)
  load_villager_sprites()
  draw_isometric_grid(w)
  local entities = {}
  for _, pair in ipairs(world.world_query(w, "kind")) do
    local eid = pair.eid
    local pos = world.world_get(w, eid, "position")
    if pos then
      table.insert(entities, {
        eid = eid,
        depth = iso.depth_key(pos.x, pos.y)
      })
    end
  end
  table.sort(entities, function(a, b)
    if a.depth == b.depth then
      return a.eid < b.eid
    else
      return a.depth < b.depth
    end
  end)
  for _, e in ipairs(entities) do
    draw_entity(w, e.eid)
  end
end

return {
  ["draw-world"] = draw_world,
  draw_world = draw_world,
  ["draw-entity"] = draw_entity,
  draw_entity = draw_entity,
  ["tile-w"] = tile_w,
  tile_w = tile_w,
  ["tile-h"] = tile_h,
  tile_h = tile_h,
  ["toggle-grid"] = toggle_grid,
  toggle_grid = toggle_grid
}
