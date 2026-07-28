local sprite_sheet = require("src.render.sprite-sheet")
local function make_animation(sprites, speed, looping)
  local _1_
  if (looping == nil) then
    _1_ = true
  else
    _1_ = looping
  end
  return {sprites = sprites, speed = (speed or 15), looping = _1_, ["current-frame"] = 0, elapsed = 0, ["total-frames"] = (5 * sprite_sheet["frames-per-direction"]), playing = true}
end
local function update(anim, dt)
  if anim.playing then
    anim.elapsed = (anim.elapsed + dt)
    local frame_duration = (1 / anim.speed)
    while (anim.elapsed >= frame_duration) do
      anim.elapsed = (anim.elapsed - frame_duration)
      anim["current-frame"] = (anim["current-frame"] + 1)
      if (anim["current-frame"] >= anim["total-frames"]) then
        if anim.looping then
          anim["current-frame"] = 0
        else
          anim["current-frame"] = (anim["total-frames"] - 1)
          anim.playing = false
        end
      else
      end
    end
    return nil
  else
    return nil
  end
end
local function get_sprite(anim, entity_direction)
  local walk_frame = (anim["current-frame"] % sprite_sheet["frames-per-direction"])
  local frame = ((entity_direction * sprite_sheet["frames-per-direction"]) + walk_frame)
  return sprite_sheet["get-frame"](anim.sprites, frame)
end
local function reset(anim)
  anim["current-frame"] = 0
  anim.elapsed = 0
  anim.playing = true
  return nil
end
local function play(anim)
  anim.playing = true
  return nil
end
local function pause(anim)
  anim.playing = false
  return nil
end
local function set_speed(anim, speed)
  anim.speed = speed
  return nil
end
return {["make-animation"] = make_animation, make_animation = make_animation, update = update, ["get-sprite"] = get_sprite, get_sprite = get_sprite, reset = reset, play = play, pause = pause, ["set-speed"] = set_speed, set_speed = set_speed}
