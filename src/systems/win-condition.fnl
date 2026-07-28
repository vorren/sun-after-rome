;; aurelius.systems.win-condition --- checks for win/loss each tick.
;; Win condition: all enemy Town Centres destroyed.

(local world (require :src.world))
(local log (require :src.log))

(var winner nil)
(var game-started false)

(fn check-win [w]
  "Check if any faction has won by destroying all enemy Town Centres."
  (when (and (not winner) game-started)
    (for [p 0 (- w.num-players 1)]
      (var tc-count 0)
      (each [_ pair (ipairs (world.world-query w :kind))]
        (let [eid pair.eid
              kind pair.val
              owner (world.world-get w eid :owner)]
          (when (and owner
                     (= owner.player p)
                     (= kind.tag :town-centre)
                     (world.world-has? w eid :health))
            (let [health (world.world-get w eid :health)]
              (when (> health.hp 0)
                (set tc-count (+ tc-count 1)))))))
      (when (= tc-count 0)
        ;; this player lost all TCs — other player wins
        (let [winner-player (if (= p 0) 1 0)]
          (set winner winner-player)
          (log.info :win-condition (.. "Player " (+ winner-player 1) " wins!"))))))
  winner)

(fn start-game []
  "Mark game as started (call after initial entities are spawned)."
  (set game-started true))

(fn get-winner []
  "Get the winning player (0 or 1), or nil if game is still in progress."
  winner)

(fn set-winner [w player]
  "Set the winner (for concede)."
  (when (not winner)
    (set winner player)
    (log.info :win-condition (.. "Player " (+ player 1) " wins by concession!"))))

(fn reset-winner []
  "Reset winner state (for new game)."
  (set winner nil)
  (set game-started false))

{: check-win : start-game : get-winner : set-winner : reset-winner}
