-- aurelius.render.floating-text --- floating text feedback for commands.

local world = require("src.world")
local iso = require("src.render.iso")
local camera = require("src.render.camera")

local texts = {}

local function add_text(w, eid, label)
  local pos = world.world_get(w, eid, "position")
  if pos then
    table.insert(texts, {
      eid = eid,
      label = label,
      lifetime = 1.0,
      x = pos.x,
      y = pos.y,
    })
  end
end

local function update_texts(dt)
  local i = 1
  while i <= #texts do
    local t = texts[i]
    t.lifetime = t.lifetime - dt
    if t.lifetime <= 0 then
      table.remove(texts, i)
    end
    if t.lifetime > 0 then
      i = i + 1
    end
  end
end

local function draw_texts(w)
  for _, t in ipairs(texts) do
    local pos = world.world_get(w, t.eid, "position")
    if pos then
      local tile_w = 64
      local tile_h = 32
      local offset_x, offset_y = camera.get_offset()
      local sx, sy = iso.to_screen(pos.x, pos.y, tile_w, tile_h)
      local screen_x = sx + offset_x
      local screen_y = sy + offset_y
      local alpha = math.min(1.0, t.lifetime)
      love.graphics.setColor(1, 1, 1, alpha)
      love.graphics.printf(t.label, screen_x - 30, screen_y - 30, 60, "center")
    end
  end
end

local function clear_texts()
  texts = {}
end

return {
  add_text = add_text,
  update_texts = update_texts,
  draw_texts = draw_texts,
  clear_texts = clear_texts,
}
