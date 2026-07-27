;; Test: Combat system
(local luaunit (require :luaunit))
(local world (require :src.world))
(local sim (require :src.sim))
(local combat (require :src.systems.combat))

{:test-attack-damage-deterministic
 (fn []
   (let [w1 (world.make-world {:seed 42})
         w2 (world.make-world {:seed 42})]
     (each [_ w (ipairs [w1 w2])]
       (world.spawn! w :knight {:owner 0 :x 5 :y 5})
       (world.spawn! w :archer {:owner 1 :x 6 :y 5}))
     ;; Entity 1 = knight, entity 2 = archer
     (let [d1 (combat.attack-damage w1 1 2)
           d2 (combat.attack-damage w2 1 2)]
       (luaunit.assertEquals d1 d2))))

  :test-knight-beats-archer
 (fn []
   (let [w (world.make-world {:seed 42})
         orders (require :src.orders)]
     (world.spawn! w :knight {:owner 0 :x 5 :y 5})
     (world.spawn! w :archer {:owner 1 :x 6 :y 5})
     ;; Entity 1 = knight, entity 2 = archer
     (orders.issue! w (orders.attack 1 2))
     ;; Attack for 60 ticks
     (for [_ 1 60]
       (sim.tick! w))
     ;; Archer should be dead
     (luaunit.assertFalse (world.world-has? w 2 :health))))

 :test-pikeman-bonus-vs-cavalry
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :pikeman {:owner 0 :x 5 :y 5})
     (world.spawn! w :knight {:owner 1 :x 6 :y 5})
     (world.spawn! w :archer {:owner 1 :x 6 :y 6})
     ;; Entity 1 = pikeman, 2 = knight, 3 = archer
     ;; Pike vs knight should do more damage than pike vs archer
     (let [d-pk (combat.attack-damage w 1 2)
           d-pa (combat.attack-damage w 1 3)]
       (luaunit.assertTrue (> d-pk d-pa)))))}
