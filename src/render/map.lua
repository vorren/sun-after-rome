-- aurelius.render.map --- Tiled map loading + procedural generation.

local world = require("src.world")

local current_map = nil
local use_procedural = true

-- Procedural map generation using LÖVE's built-in Perlin noise
local function generate_procedural(w, seed)
  local terrain = {}
  math.randomseed(seed or 42)
  for x = 0, w.width - 1 do
    terrain[x] = {}
    for y = 0, w.height - 1 do
      local n = love.math.noise(x * 0.1, y * 0.1, 0.5)
      local tile
      if n < 0.3 then
        tile = "water"
      elseif n < 0.5 then
        tile = "grass"
      elseif n < 0.7 then
        tile = "dirt"
      elseif n < 0.85 then
        tile = "forest"
      else
        tile = "stone"
      end
      terrain[x][y] = tile
    end
  end
  return terrain
end

local function draw_terrain(terrain, w)
  if terrain then
    local iso = require("src.render.iso")
    for x = 0, w.width - 1 do
      for y = 0, w.height - 1 do
        local tile = terrain[x][y]
        local raw_sx, raw_sy = iso.to_screen(x, y, 64, 32)
        -- Offset to center
        local sx = raw_sx + 640
        local sy = raw_sy + 100
        if tile == "water" then
          love.graphics.setColor(0.2, 0.4, 0.8)
        elseif tile == "grass" then
          love.graphics.setColor(0.3, 0.6, 0.2)
        elseif tile == "dirt" then
          love.graphics.setColor(0.6, 0.5, 0.3)
        elseif tile == "forest" then
          love.graphics.setColor(0.1, 0.4, 0.1)
        elseif tile == "stone" then
          love.graphics.setColor(0.5, 0.5, 0.5)
        else
          love.graphics.setColor(0.3, 0.3, 0.3)
        end
        -- Draw filled diamond
        love.graphics.polygon("fill",
          sx, sy - 16,
          sx + 32, sy,
          sx, sy + 16,
          sx - 32, sy)
      end
    end
  end
end

local function init_map(w, seed)
  if use_procedural then
    return generate_procedural(w, seed)
  end
end

return {
  ["generate-procedural"] = generate_procedural,
  ["draw-terrain"] = draw_terrain,
  ["init-map"] = init_map
}
