local log = require("src.log")
local cache = {}
local directions = {south = 0, ["south-west"] = 1, west = 2, ["north-west"] = 3, north = 4, ["north-east"] = 5, east = 6, ["south-east"] = 7}
local frames_per_direction = 15
local function direction_index(frame)
  return math.floor((frame / frames_per_direction))
end
local function needs_mirror_3f(frame)
  return (direction_index(frame) >= 5)
end
local function mirror_direction(frame)
  local idx = direction_index(frame)
  if (idx == 5) then
    return 3
  elseif (idx == 6) then
    return 2
  elseif (idx == 7) then
    return 1
  else
    return idx
  end
end
local function frame_number(frame)
  return (frame % frames_per_direction)
end
local function load_sprite(path)
  local or_2_ = cache[path]
  if not or_2_ then
    local ok, img = pcall(love.graphics.newImage, path)
    if ok then
      cache[path] = img
      or_2_ = img
    else
      log.warn("sprite-sheet", ("Failed to load: " .. path))
      or_2_ = nil
    end
  end
  return or_2_
end
local function load_animation(directory, prefix, count)
  local sprites = {}
  local loaded = 0
  for i = 1, count do
    local num = string.format("%03d", i)
    local path = (directory .. "/" .. prefix .. num .. ".png")
    local img = load_sprite(path)
    table.insert(sprites, img)
    if img then loaded = loaded + 1 end
  end
  if loaded == 0 then
    log.warn("sprite-sheet", "No sprites loaded from: " .. directory)
  end
  return sprites
end
local function get_frame(sprites, frame)
  local idx = direction_index(frame)
  local fnum = frame_number(frame)
  local source_idx
  if (idx >= 5) then
    source_idx = mirror_direction(frame)
  else
    source_idx = idx
  end
  local source_frame = ((source_idx * frames_per_direction) + fnum + 1)
  local img = sprites[source_frame]
  return {image = img, mirror = needs_mirror_3f(frame)}
end
local function clear_cache()
  cache = {}
  return log.info("sprite-sheet", "Cache cleared")
end
return {directions = directions, ["frames-per-direction"] = frames_per_direction, frames_per_direction = frames_per_direction, ["load-animation"] = load_animation, load_animation = load_animation, ["get-frame"] = get_frame, get_frame = get_frame, ["clear-cache"] = clear_cache, clear_cache = clear_cache, ["direction-index"] = direction_index, direction_index = direction_index, ["needs-mirror?"] = needs_mirror_3f, ["needs_mirror?"] = needs_mirror_3f, ["frame-number"] = frame_number, frame_number = frame_number}
