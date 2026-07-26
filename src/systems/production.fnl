;; aurelius.systems.production --- buildings train queued units.
;; Cost was already paid when the 'train' command was enqueued (ADR-0009).

(local world (require :src.world))
(local content (require :src.content))

(fn production-system [w]
  (each [_ pair (ipairs (world.world-query w :producer))]
    (let [prod pair.eid p pair.val]
      (when (> (# p.queue) 0)
        (let [tag (. p.queue 1)
              prog (+ 1 p.progress)]
          (if (>= prog (content.train-time tag))
              (let [pos (world.world-get w prod :position)
                    own (world.world-get w prod :owner)]
                (world.spawn! w tag
                              {:owner (and own own.player)
                               :x (math.min (- w.width 1) (+ 1 pos.x))
                               :y pos.y})
                (table.remove p.queue 1)
                (set p.progress 0))
              (set p.progress prog)))))))

{: production-system}
