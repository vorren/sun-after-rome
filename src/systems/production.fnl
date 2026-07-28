;; aurelius.systems.production --- buildings train queued units.
;; Cost was already paid when the 'train' command was enqueued (ADR-0009).

(local world (require :src.world))
(local content (require :src.content))
(local orders (require :src.orders))

(fn production-system [w]
  (each [_ pair (ipairs (world.world-query w :producer))]
    (let [prod pair.eid p pair.val]
      (when (> (# p.queue) 0)
        (let [tag (. p.queue 1)
              prog (+ 1 p.progress)]
          (if (>= prog (content.train-time tag))
              (let [pos (world.world-get w prod :position)
                    own (world.world-get w prod :owner)
                    ;; use rally point if set, otherwise spawn near building
                    spawn-x (if p.rally-x p.rally-x
                                (math.min (- w.width 1) (+ 1 pos.x)))
                    spawn-y (if p.rally-y p.rally-y pos.y)
                    eid (world.spawn! w tag
                                     {:owner (and own own.player)
                                      :x spawn-x
                                      :y spawn-y})]
                ;; if rally point is set and unit isn't already there, order it to move
                (when (and p.rally-x p.rally-y
                           (or (not= spawn-x p.rally-x)
                               (not= spawn-y p.rally-y)))
                  (orders.issue! w (orders.move eid p.rally-x p.rally-y)))
                (table.remove p.queue 1)
                (set p.progress 0))
              (set p.progress prog)))))))

{: production-system}
