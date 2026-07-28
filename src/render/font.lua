-- aurelius.render.font --- font management.
-- Loads and manages fonts for HUD rendering.

local font_sm = nil
local font_md = nil
local font_lg = nil

local function load_fonts()
  font_sm = love.graphics.newFont(12)
  font_md = love.graphics.newFont(16)
  font_lg = love.graphics.newFont(24)
  love.graphics.setFont(font_md)
end

local function get_font(size)
  if size == "sm" then
    return font_sm
  elseif size == "lg" then
    return font_lg
  else
    return font_md
  end
end

return { load_fonts = load_fonts, get_font = get_font }
