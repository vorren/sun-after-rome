-- aurelius.render.camera --- viewport position for scrolling.
-- Holds the screen offset that determines what part of the world is visible.

local offset_x = 640
local offset_y = 100

-- Get current camera offset.
local function get_offset()
  return offset_x, offset_y
end

-- Set camera offset.
local function set_offset(x, y)
  offset_x = x
  offset_y = y
end

-- Scroll camera so that (tile_x, tile_y) is at screen center.
local function scroll_to_tile(tile_x, tile_y, tile_w, tile_h, screen_w, screen_h)
  local hw = tile_w / 2
  local hh = tile_h / 2
  local raw_sx = (tile_x - tile_y) * hw
  local raw_sy = (tile_x + tile_y) * hh
  offset_x = screen_w / 2 - raw_sx
  offset_y = screen_h / 2 - raw_sy
end

-- Reset camera to default position.
local function reset()
  offset_x = 640
  offset_y = 100
end

return {get_offset = get_offset, set_offset = set_offset, scroll_to_tile = scroll_to_tile, reset = reset}
