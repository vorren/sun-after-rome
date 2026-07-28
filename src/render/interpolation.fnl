;; aurelius.render.interpolation --- frame interpolation between ticks.
;; Stores previous positions and provides alpha for smooth rendering.

(local world (require :src.world))

(var prev-positions {})
(var alpha 0)

(fn save-positions [w]
  "Save current positions before tick for interpolation."
  (set prev-positions {})
  (each [_ pair (ipairs (world.world-query w :position))]
    (let [eid pair.eid
          pos pair.val]
      (tset prev-positions eid {:x pos.x :y pos.y}))))

(fn set-alpha [a]
  "Set interpolation alpha (0..1) based on accumulator."
  (set alpha a))

(fn get-alpha []
  "Get current interpolation alpha."
  alpha)

(fn interpolated-pos [w eid]
  "Get interpolated position for entity EID."
  (let [curr (world.world-get w eid :position)
        prev (. prev-positions eid)]
    (when curr
      (if (and prev (< alpha 1))
          {:x (+ prev.x (* (- curr.x prev.x) alpha))
           :y (+ prev.y (* (- curr.y prev.y) alpha))}
          curr))))

(fn clear []
  "Clear interpolation state."
  (set prev-positions {})
  (set alpha 0))

{: save-positions : set-alpha : get-alpha : interpolated-pos : clear}
