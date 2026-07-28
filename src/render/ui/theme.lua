-- aurelius.render.ui.theme --- Golden hour theme for Sun After Rome.
-- Warm browns, golds, terracotta — the visual signature.

local M = {}

function M.hex_to_rgb(hex)
  local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
  return {
    tonumber(r, 16) / 255,
    tonumber(g, 16) / 255,
    tonumber(b, 16) / 255
  }
end

function M.resolve_color(color)
  if type(color) == "string" then
    return M.hex_to_rgb(color)
  end
  return color
end

M.golden_hour = {
  -- Backgrounds
  parchment = "#F5E6C8",
  ["parchment-dim"] = "#E8D5B0",

  -- Borders and emphasis
  terracotta = "#C1694F",
  ["terracotta-light"] = "#D4835E",
  ["terracotta-dark"] = "#A8553D",

  -- Text and grounding
  brown = "#3D2B1F",
  ["brown-light"] = "#5A4A3A",
  ["brown-lighter"] = "#8B7355",

  -- Accents
  gold = "#D4A017",
  ["gold-bright"] = "#E8B82A",
  ["gold-dim"] = "#B89015",

  -- Nature
  sage = "#7D8A5A",
  ["sage-light"] = "#9AAB72",
  ["sage-dark"] = "#5F6B42",

  -- Sky
  sky = "#6B9AC4",
  ["sky-light"] = "#8AB4D8",
  ["sky-dark"] = "#4F7BA5",

  -- Feedback
  glow = "#FFD700",
  shadow = "#5A4A3A",

  -- Transparent
  clear = { 0, 0, 0, 0 }
}

M.theme_defaults = {
  -- Panel
  ["panel-bg"] = "parchment",
  ["panel-border"] = "terracotta",
  ["panel-border-w"] = 2,
  ["panel-radius"] = 0,
  ["panel-pad"] = 8,

  -- Label
  ["label-color"] = "brown",
  ["label-font"] = "md",

  -- Icon
  ["icon-scale"] = 1,
  ["icon-color"] = "brown",

  -- Bar
  ["bar-fill"] = "gold",
  ["bar-bg"] = "brown",
  ["bar-border"] = "terracotta",
  ["bar-h"] = 12,

  -- Button
  ["btn-bg"] = "terracotta",
  ["btn-hover"] = "terracotta-light",
  ["btn-active"] = "terracotta-dark",
  ["btn-color"] = "parchment",
  ["btn-radius"] = 2,

  -- Layout
  gap = 4,
  pad = 8,

  -- Typography
  fonts = {
    sm = 12,
    md = 14,
    lg = 20,
    xl = 28
  }
}

function M.make_theme(overrides)
  local t = {}
  for k, v in pairs(M.theme_defaults) do
    t[k] = v
  end
  for k, v in pairs(overrides or {}) do
    t[k] = v
  end
  for k, v in pairs(M.golden_hour) do
    t[k] = M.resolve_color(v)
  end
  return t
end

return M
