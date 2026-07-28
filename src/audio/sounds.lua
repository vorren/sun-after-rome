local sounds = {}
local function load_sounds()
  do
    local ok, move = pcall(love.audio.newSource, "assets/sounds/move.ogg", "static")
    if ok then
      sounds.move = move
    else
    end
  end
  do
    local ok, gather = pcall(love.audio.newSource, "assets/sounds/gather.ogg", "static")
    if ok then
      sounds.gather = gather
    else
    end
  end
  local ok, attack = pcall(love.audio.newSource, "assets/sounds/attack.ogg", "static")
  if ok then
    sounds.attack = attack
    return nil
  else
    return nil
  end
end
local function play(name)
  local s = sounds[name]
  if s then
    s:stop()
    return s:play()
  else
    return nil
  end
end
return {["load-sounds"] = load_sounds, load_sounds = load_sounds, play = play}
