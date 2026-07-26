;; aurelius.systems.age --- per-faction age advancement (ADR-0011).
;; Ticks the countdown; when it hits zero the age level increments.

(local world (require :src.world))

(fn age-system [w]
  (for [p 1 w.num-players]
    (let [left (world.age-progress w p)]
      (when left
        (if (<= left 1)
            (do (world.set-player-age! w p (+ 1 (world.player-age w p)))
                (world.set-age-progress! w p nil))
            (world.set-age-progress! w p (- left 1)))))))

{: age-system}
