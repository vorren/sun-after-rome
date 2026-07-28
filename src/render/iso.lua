-- aurelius.render.iso --- isometric coordinate transforms.

local screen_offset_x = 640
local screen_offset_y = 100

local function to_screen(tile_x, tile_y, tile_w, tile_h)
  return ((tile_x - tile_y) * (tile_w / 2)),
         ((tile_x + tile_y) * (tile_h / 2))
end

local function to_tile(screen_x, screen_y, tile_w, tile_h)
  local hw = tile_w / 2
  local hh = tile_h / 2
  return ((screen_x / hw) + (screen_y / hh)) / 2,
         ((screen_y / hh) - (screen_x / hw)) / 2
end

local function depth_key(tile_x, tile_y)
  return tile_y + (tile_x * 1000)
end

return {
  to_screen = to_screen,
  to_tile = to_tile,
  depth_key = depth_key,
  screen_offset_x = screen_offset_x,
  screen_offset_y = screen_offset_y
}
