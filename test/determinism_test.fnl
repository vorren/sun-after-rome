;; Test: Determinism - same seed + commands = same world
(local luaunit (require :luaunit))
(local world (require :src.world))
(local sim (require :src.sim))
(local orders (require :src.orders))

(fn world-signature [w]
  (let [sig {:tick w.tick :next-id w.next-id :resources {} :entities {}}]
    ;; Resources
    (for [p 1 w.num-players]
      (tset sig.resources p {})
      (each [res val (pairs (. w.resources p))]
        (tset (. sig.resources p) res val)))
    ;; Entity kinds + positions + health
    (each [_ pair (ipairs (world.world-query w :kind))]
      (let [eid pair.eid
            tag pair.val.tag
            pos (world.world-get w eid :position)
            hp (world.world-get w eid :health)]
        (tset sig.entities eid {:tag tag
                                :x (and pos pos.x)
                                :y (and pos pos.y)
                                :hp (and hp hp.hp)})))
    sig))

{:test-same-seed-same-result
 (fn []
   (let [w1 (world.make-world {:seed 42})
         w2 (world.make-world {:seed 42})]
     ;; Same setup
     (each [_ w (ipairs [w1 w2])]
       (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
       (world.spawn! w :villager {:owner 0 :x 4 :y 4})
       (world.spawn! w :tree {:x 8 :y 6}))
     ;; Same commands
     (orders.issue! w1 (orders.gather 2 4))
     (orders.issue! w2 (orders.gather 2 4))
     ;; Run same ticks
     (sim.run! w1 50)
     (sim.run! w2 50)
     ;; Signatures must match
     (luaunit.assertEquals (world-signature w1) (world-signature w2))))

 :test-different-seeds-diverge
 (fn []
   ;; Different seeds produce different RNG states
   ;; We test this directly via the RNG, not via full simulation
   ;; (because without commands, simulation is deterministic regardless of seed)
   (let [r1 (require :src.rng)
         rng1 (r1.make-rng 1)
         rng2 (r1.make-rng 999)]
     (var same true)
     (for [_ 1 10]
       (when (not= (r1.rng-next! rng1) (r1.rng-next! rng2))
         (set same false)))
     (luaunit.assertFalse same)))

 :test-snapshot-independence
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.spawn! w :tree {:x 8 :y 6})
     (sim.tick! w)
     (let [snap (world.snapshot w)]
       (sim.run! w 30)
       ;; Snapshot should not have changed
       (luaunit.assertEquals snap.tick 1)
       ;; Live world should have advanced
       (luaunit.assertEquals w.tick 31))))}
