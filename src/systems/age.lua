-- aurelius.systems.age --- per-faction age advancement (ADR-0011).
-- Ticks the countdown; when it hits zero the age level increments.

local world = require("src.world")

local function age_system(w)
  for p = 1, w.num_players do
    local left = world.age_progress(w, p)
    if left then
      if left <= 1 then
        world.set_player_age(w, p, 1 + world.player_age(w, p))
        world.set_age_progress(w, p, nil)
      else
        world.set_age_progress(w, p, left - 1)
      end
    end
  end
end

return {age_system = age_system}
