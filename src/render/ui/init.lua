-- aurelius.render.ui --- Data-driven UI for Sun After Rome.
-- Layouts are tables, not code. Single draw-ui function renders everything.

local log = require("src.log")
local theme = require("src.render.ui.theme")

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------

local current_theme = theme.make_theme()
local hover_id = nil
local click_id = nil
local widget_bounds = {}
local font_cache = {}

-- ---------------------------------------------------------------------------
-- Font
-- ---------------------------------------------------------------------------

local function get_font(size)
  -- Get or create a font at SIZE px. Cached.
  if font_cache[size] then
    return font_cache[size]
  else
    local f = love.graphics.newFont(size)
    font_cache[size] = f
    return f
  end
end

local function resolve_font(font_key)
  -- Resolve :sm/:md/:lg/:xl to a LOVE Font object.
  local size
  if current_theme and current_theme.fonts[font_key] then
    size = current_theme.fonts[font_key]
  elseif font_key and type(font_key) == "number" then
    size = font_key
  else
    size = 14
  end
  return get_font(size)
end

-- ---------------------------------------------------------------------------
-- Color
-- ---------------------------------------------------------------------------

local function resolve(color)
  -- Resolve a color: HEXSTRING, RGB table, or theme key.
  if type(color) == "string" then
    if current_theme[color] then
      return current_theme[color]
    else
      return theme.hex_to_rgb(color)
    end
  elseif type(color) == "table" then
    return color
  else
    return {1, 1, 1}
  end
end

local function set_color(color, alpha)
  -- Set love.graphics.setColor from resolved color + optional alpha.
  local r, g, b = color[1], color[2], color[3]
  local a = alpha or color[4] or 1
  love.graphics.setColor(r, g, b, a)
end

-- ---------------------------------------------------------------------------
-- Position: relative resolution
-- ---------------------------------------------------------------------------

local function resolve_x(x, w, screen_w)
  -- Resolve :right-N, :center-N, or absolute x.
  if x == "left" then
    return 0
  elseif x == "right" then
    return screen_w - w
  elseif x == "center" then
    return (screen_w - w) / 2
  elseif type(x) == "string" then
    local rel, offset = x:match("^:(%w+)[%-+](%d+)$")
    if rel == "right" then
      return screen_w - w - tonumber(offset)
    elseif rel == "center" then
      return (screen_w - w) / 2
    elseif rel == "bottom" then
      return 0
    elseif rel == "top" then
      return 0
    else
      return tonumber(offset)
    end
  else
    return x or 0
  end
end

local function resolve_y(y, h, screen_h)
  -- Resolve :bottom-N, :center-N, or absolute y.
  if y == "top" then
    return 0
  elseif y == "bottom" then
    return screen_h - h
  elseif y == "center" then
    return (screen_h - h) / 2
  elseif type(y) == "string" then
    local rel, offset = y:match("^:(%w+)[%-+](%d+)$")
    if rel == "bottom" then
      return screen_h - h - tonumber(offset)
    elseif rel == "center" then
      return (screen_h - h) / 2
    elseif rel == "right" then
      return 0
    elseif rel == "left" then
      return 0
    else
      return tonumber(offset)
    end
  else
    return y or 0
  end
end

-- ---------------------------------------------------------------------------
-- Layout engine
-- ---------------------------------------------------------------------------

local function measure_text(text, font)
  -- Get width and height of text.
  local f = resolve_font(font)
  local w, h = f:getWidth(text)
  return w, h
end

local function auto_size_children(node)
  -- Compute size of panel from children.
  local max_w = 0
  local total_h = 0
  local dir = node.dir or "vert"
  local gap = node.gap or current_theme.gap
  for _, child in ipairs(node.children or {}) do
    auto_size_children(child)
    if dir == "vert" then
      max_w = math.max(max_w, (child.w or 0))
      total_h = total_h + (child.h or 0) + gap
    else
      max_w = max_w + (child.w or 0) + gap
      total_h = math.max(total_h, (child.h or 0))
    end
  end
  if dir == "vert" then
    total_h = total_h - gap
  end
  if dir == "horiz" then
    max_w = max_w - gap
  end
  return max_w, total_h
end

local function layout_children(node)
  -- Position children in panel based on :dir and :gap.
  local dir = node.dir or "vert"
  local gap = node.gap or current_theme.gap
  local pad = node.pad or current_theme.pad
  local pad_top = node["pad-top"] or pad
  local pad_left = node["pad-left"] or pad
  local x0 = node.x + pad_left
  local y0 = node.y + pad_top
  local cx = x0
  local cy = y0
  for _, child in ipairs(node.children or {}) do
    child.x = cx
    child.y = cy
    if dir == "vert" then
      cy = cy + (child.h or 0) + gap
    else
      cx = cx + (child.w or 0) + gap
    end
    layout_children(child)
  end
end

local function resolve_position(node, screen_w, screen_h)
  -- Resolve relative positions to absolute.
  node.x = resolve_x(node.x, (node.w or 0), screen_w)
  node.y = resolve_y(node.y, (node.h or 0), screen_h)
  for _, child in ipairs(node.children or {}) do
    resolve_position(child, screen_w, screen_h)
  end
end

local function compute_bounds(node)
  -- Store bounds for hit-testing.
  if node.id then
    widget_bounds[node.id] = {x = node.x, y = node.y, w = (node.w or 0), h = (node.h or 0)}
  end
  for _, child in ipairs(node.children or {}) do
    compute_bounds(child)
  end
end

local function layout(node, screen_w, screen_h)
  -- One-pass layout: auto-size, position, compute bounds.
  widget_bounds = {}
  auto_size_children(node)
  resolve_position(node, screen_w, screen_h)
  layout_children(node)
  compute_bounds(node)
end

-- ---------------------------------------------------------------------------
-- Drawing primitives
-- ---------------------------------------------------------------------------

local function draw_panel(node)
  -- Draw panel: filled rectangle + border.
  local bg = resolve(node.color or current_theme["panel-bg"])
  local border = resolve(node.border or current_theme["panel-border"])
  local border_w = node["border-w"] or current_theme["panel-border-w"]
  if bg then
    set_color(bg, node.alpha or 1)
    love.graphics.rectangle("fill", node.x, node.y, (node.w or 0), (node.h or 0))
  end
  if border then
    set_color(border, node.alpha or 1)
    love.graphics.setLineWidth(border_w)
    love.graphics.rectangle("line", node.x, node.y, (node.w or 0), (node.h or 0))
  end
end

local function draw_label(node)
  -- Draw label: text at position.
  local color = resolve(node.color or current_theme["label-color"])
  local font = resolve_font(node.font or current_theme["label-font"])
  local text = node.text or ""
  local align = node.align or "left"
  love.graphics.setFont(font)
  set_color(color, node.alpha or 1)
  love.graphics.printf(text, node.x, node.y, (node.w or 9999), align)
end

local function draw_icon(node)
  -- Draw icon: colored circle with initial letter (placeholder).
  local color = resolve(node.color or current_theme["icon-color"])
  local size = node.scale or current_theme["icon-scale"]
  local r = 8 * size
  local text = string.sub(node.text or "?", 1, 1)
  set_color(color, node.alpha or 1)
  love.graphics.circle("fill", node.x + r, node.y + r, r)
  love.graphics.setColor(1, 1, 1, node.alpha or 1)
  local font = resolve_font(8 * size)
  love.graphics.setFont(font)
  love.graphics.printf(text, node.x + (r - 4), node.y + (r - 6), r * 2, "center")
end

local function draw_bar(node)
  -- Draw bar: background + fill + border.
  local fill = resolve(node.fill or current_theme["bar-fill"])
  local bg = resolve(node.bg or current_theme["bar-bg"])
  local border = resolve(node.border or current_theme["bar-border"])
  local w = node.w or 100
  local h = node.h or current_theme["bar-h"]
  local value = node.value or 0
  local ratio = math.min(1, math.max(0, node.max and (value / node.max) or value))
  local fill_w = w * ratio
  if bg then
    set_color(bg, node.alpha or 1)
    love.graphics.rectangle("fill", node.x, node.y, w, h)
  end
  if fill then
    set_color(fill, node.alpha or 1)
    love.graphics.rectangle("fill", node.x, node.y, fill_w, h)
  end
  if border then
    set_color(border, node.alpha or 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", node.x, node.y, w, h)
  end
end

local function draw_button(node)
  -- Draw button: background + label + hover/active state.
  local is_hover = hover_id == node.id
  local is_click = click_id == node.id
  local bg
  if is_click then
    bg = resolve(node["active-color"] or current_theme["btn-active"])
  elseif is_hover then
    bg = resolve(node["hover-color"] or current_theme["btn-hover"])
  else
    bg = resolve(node.color or current_theme["btn-bg"])
  end
  local text_color = resolve(node["text-color"] or current_theme["btn-color"])
  local w = node.w or 80
  local h = node.h or 30
  if bg then
    set_color(bg, node.alpha or 1)
    love.graphics.rectangle("fill", node.x, node.y, w, h, node.radius or current_theme["btn-radius"])
  end
  if text_color then
    local font = resolve_font(node.font or "md")
    local text = node.text or ""
    love.graphics.setFont(font)
    set_color(text_color, node.alpha or 1)
    love.graphics.printf(text, node.x, node.y, w, "center")
  end
end

-- ---------------------------------------------------------------------------
-- Draw dispatch
-- ---------------------------------------------------------------------------

local function draw_node(node)
  -- Draw a node and its children.
  if node.type == "panel" then
    draw_panel(node)
    for _, child in ipairs(node.children or {}) do
      draw_node(child)
    end
  elseif node.type == "label" then
    draw_label(node)
  elseif node.type == "icon" then
    draw_icon(node)
  elseif node.type == "bar" then
    draw_bar(node)
  elseif node.type == "button" then
    draw_button(node)
  else
    log.warn("ui", "Unknown node type: " .. tostring(node.type))
  end
end

-- ---------------------------------------------------------------------------
-- Hit-testing
-- ---------------------------------------------------------------------------

local function point_in_rect(px, py, rx, ry, rw, rh)
  -- Check if point is inside rectangle.
  return (px >= rx) and (px <= rx + rw) and (py >= ry) and (py <= ry + rh)
end

local function hit_test(node, px, py)
  -- Find deepest node at (px, py). Buttons win over panels.
  local result = nil
  if node then
    if node.id and point_in_rect(px, py, node.x, node.y, (node.w or 0), (node.h or 0)) then
      result = node
    end
    for _, child in ipairs(node.children or {}) do
      local child_hit = hit_test(child, px, py)
      if child_hit then
        result = child_hit
      end
    end
  end
  return result
end

-- ---------------------------------------------------------------------------
-- Mouse handling
-- ---------------------------------------------------------------------------

local function handle_mouse_move(node, mx, my)
  -- Update hover state.
  local hit = hit_test(node, mx, my)
  hover_id = hit and hit.id or nil
end

local function handle_click(node, mx, my)
  -- Fire on-click if a button was clicked.
  local hit = hit_test(node, mx, my)
  if hit and hit["on-click"] then
    click_id = hit.id
    hit["on-click"](hit)
  end
  return hit
end

local function clear_click()
  -- Clear click state (call after frame).
  click_id = nil
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

local function init(theme_overrides)
  -- Initialize UI with a theme.
  current_theme = theme.make_theme(theme_overrides)
  hover_id = nil
  click_id = nil
  widget_bounds = {}
  font_cache = {}
  log.info("ui", "UI initialized")
end

local function draw(node)
  -- Draw a UI tree.
  local sw, sh = love.graphics.getDimensions()
  layout(node, sw, sh)
  draw_node(node)
end

local function root(props, ...)
  -- Create a root node.
  local flat_children = {}
  local children = {...}

  local function flatten(node)
    if type(node) == "table" then
      if node.type then
        table.insert(flat_children, node)
      else
        for _, v in ipairs(node) do
          flatten(v)
        end
      end
    elseif node then
      table.insert(flat_children, node)
    end
  end

  flatten(children)
  return {
    type = "panel",
    x = props.x or 0,
    y = props.y or 0,
    w = props.w,
    h = props.h,
    alpha = props.alpha,
    children = flat_children
  }
end

return {
  ["init"] = init,
  ["draw"] = draw,
  ["root"] = root,
  ["handle-mouse-move"] = handle_mouse_move,
  handle_mouse_move = handle_mouse_move,
  ["handle-click"] = handle_click,
  handle_click = handle_click,
  ["clear-click"] = clear_click,
  clear_click = clear_click,
  ["resolve"] = resolve,
  ["set-color"] = set_color,
  set_color = set_color,
  ["get-font"] = get_font,
  get_font = get_font,
  ["resolve-font"] = resolve_font,
  resolve_font = resolve_font,
  ["hit-test"] = hit_test,
  hit_test = hit_test,
  ["layout"] = layout
}
