-- aurelius.systems.win-condition --- checks for win/loss each tick.
-- Win condition: all enemy Town Centres destroyed.

local world = require("src.world")
local log = require("src.log")

local winner = nil
local game_started = false

-- Check if any faction has won by destroying all enemy Town Centres.
local function check_win(w)
  if (not winner) and game_started then
    for p = 0, w.num_players - 1 do
      local tc_count = 0
      for _, pair in ipairs(world.world_query(w, "kind")) do
        local eid = pair.eid
        local kind = pair.val
        local owner = world.world_get(w, eid, "owner")
        if owner
            and (owner.player == p)
            and (kind.tag == "town-centre")
            and world.world_has(w, eid, "health") then
          local health = world.world_get(w, eid, "health")
          if health.hp > 0 then
            tc_count = tc_count + 1
          end
        end
      end
      if tc_count == 0 then
        -- this player lost all TCs — other player wins
        local winner_player
        if p == 0 then
          winner_player = 1
        else
          winner_player = 0
        end
        winner = winner_player
        log.info("win-condition", "Player " .. (winner_player + 1) .. " wins!")
      end
    end
  end
  return winner
end

-- Mark game as started (call after initial entities are spawned).
local function start_game()
  game_started = true
end

-- Get the winning player (0 or 1), or nil if game is still in progress.
local function get_winner()
  return winner
end

-- Set the winner (for concede).
local function set_winner(w, player)
  if not winner then
    winner = player
    log.info("win-condition", "Player " .. (player + 1) .. " wins by concession!")
  end
end

-- Reset winner state (for new game).
local function reset_winner()
  winner = nil
  game_started = false
end

return {
  check_win = check_win,
  start_game = start_game,
  get_winner = get_winner,
  set_winner = set_winner,
  reset_winner = reset_winner
}
