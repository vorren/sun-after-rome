-- aurelius.render.ui.minimap --- mini map showing the game world.
-- Renders terrain as colored pixels, units as dots, viewport rectangle.
-- Click to scroll view, toggle with F2.

local world = require("src.world")
local iso = require("src.render.iso")
local camera = require("src.render.camera")
local log = require("src.log")

local canvas = nil
local visible = true
local last_update_tick = 0
local update_interval = 10

-- minimap dimensions
local mm_w = 180
local mm_h = 120

-- terrain colors
local terrain_colors = {
  water = {0.3, 0.5, 0.8},
  grass = {0.4, 0.6, 0.3},
  dirt = {0.6, 0.5, 0.3},
  forest = {0.2, 0.4, 0.2},
  stone = {0.5, 0.5, 0.5}
}

-- faction colors
local faction_colors = {
  [0] = {0.2, 0.4, 0.9},   -- blue
  [1] = {0.9, 0.2, 0.2}    -- red
}

local function toggle()
  -- Toggle minimap visibility.
  visible = not visible
  log.debug("minimap", visible and "shown" or "hidden")
end

local function init()
  -- Create minimap canvas.
  canvas = love.graphics.newCanvas(mm_w, mm_h)
  log.info("minimap", "Minimap initialized")
end

local function draw_terrain(w)
  -- Draw terrain pixels to canvas.
  local pixel_w = mm_w / w.width
  local pixel_h = mm_h / w.height
  -- draw terrain tiles
  for x = 0, w.width - 1 do
    for y = 0, w.height - 1 do
      local terrain = world.world_get_tile(w, x, y)
      local color = terrain_colors[terrain] or {0.5, 0.5, 0.5}
      love.graphics.setColor(color[1], color[2], color[3])
      love.graphics.rectangle("fill",
        x * pixel_w, y * pixel_h,
        pixel_w + 1, pixel_h + 1)
    end
  end
end

local function draw_entities(w)
  -- Draw entity dots on minimap.
  local pixel_w = mm_w / w.width
  local pixel_h = mm_h / w.height
  for _, pair in ipairs(world.world_query(w, "position")) do
    local eid = pair.eid
    local pos = pair.val
    local owner = world.world_get(w, eid, "owner")
    local kind = world.world_get(w, eid, "kind")
    if owner and kind then
      local color = faction_colors[owner.player] or {0.5, 0.5, 0.5}
      local px = pos.x * pixel_w
      local py = pos.y * pixel_h
      love.graphics.setColor(color[1], color[2], color[3])
      love.graphics.rectangle("fill", px - 1, py - 1, 3, 3)
    end
  end
end

local function draw_viewport(w, screen_w, screen_h)
  -- Draw viewport rectangle on minimap.
  local pixel_w = mm_w / w.width
  local pixel_h = mm_h / w.height
  -- calculate viewport in tile coordinates
  local tile_w = 64
  local tile_h = 32
  local offset_x, offset_y = camera.get_offset()
  local center_x = screen_w / 2
  local center_y = screen_h / 2
  local tile_cx, tile_cy = iso.to_tile(center_x - offset_x, center_y - offset_y, tile_w, tile_h)
  -- viewport size in tiles
  local view_w = screen_w / tile_w
  local view_h = screen_h / tile_h
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line",
    (tile_cx - (view_w / 2)) * pixel_w,
    (tile_cy - (view_h / 2)) * pixel_h,
    view_w * pixel_w,
    view_h * pixel_h)
end

local function update_canvas(w)
  -- Update minimap canvas (called every N ticks).
  if canvas and visible then
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.1, 0.1, 0.1)
    draw_terrain(w)
    draw_entities(w)
    love.graphics.setCanvas()
  end
end

local function draw(w)
  -- Draw minimap on screen.
  if visible then
    local screen_w, screen_h = love.graphics.getDimensions()
    local mm_x = screen_w - mm_w - 10
    local mm_y = screen_h - mm_h - 10
    -- update canvas periodically
    if (w.tick - last_update_tick) >= update_interval then
      update_canvas(w)
      last_update_tick = w.tick
    end
    -- draw canvas to screen
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvas, mm_x, mm_y)
    -- draw viewport rectangle
    draw_viewport(w, screen_w, screen_h)
    -- draw border
    love.graphics.setColor(0.96, 0.90, 0.78)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", mm_x, mm_y, mm_w, mm_h)
  end
end

local function handle_click(x, y, w, screen_w, screen_h)
  -- Handle click on minimap — scroll view to clicked position.
  if visible then
    local mm_x = screen_w - mm_w - 10
    local mm_y = screen_h - mm_h - 10
    local rel_x = x - mm_x
    local rel_y = y - mm_y
    if (rel_x >= 0) and (rel_x <= mm_w) and (rel_y >= 0) and (rel_y <= mm_h) then
      -- convert minimap coords to tile coords
      local tile_x = (rel_x / mm_w) * w.width
      local tile_y = (rel_y / mm_h) * w.height
      log.debug("minimap", "Scrolling to tile " .. tile_x .. "," .. tile_y)
      -- scroll camera to this tile
      camera.scroll_to_tile(tile_x, tile_y, 64, 32, screen_w, screen_h)
      return true
    end
  end
end

return {
  ["init"] = init,
  ["draw"] = draw,
  ["toggle"] = toggle,
  ["handle-click"] = handle_click
}
