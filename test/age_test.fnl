;; Test: Age advancement
(local luaunit (require :luaunit))
(local world (require :src.world))
(local content (require :src.content))
(local sim (require :src.sim))
(local orders (require :src.orders))

{:test-age-advancement
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :stone 500)
     (world.add-resource! w 0 :gold 500)
     (luaunit.assertEquals (world.player-age w 0) 1)
     (world.set-age-progress! w 0 (content.age-time 2))
     (for [_ 1 (content.age-time 2)]
       (set w.tick (+ w.tick 1))
       (let [left (world.age-progress w 0)]
         (when left
           (world.set-age-progress! w 0 (- left 1))
           (when (<= (world.age-progress w 0) 0)
             (world.set-player-age! w 0 2)
             (world.set-age-progress! w 0 nil)))))
     (luaunit.assertEquals (world.player-age w 0) 2)))

 :test-cost-check
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (luaunit.assertEquals (world.player-age w 0) 1)
     (let [before (world.resource-amount w 0 :wood)]
       (orders.issue! w (orders.advance-age 0))
       (sim.tick! w)
       (let [after (world.resource-amount w 0 :wood)]
         (luaunit.assertEquals after before)))))

 :test-max-age-cap
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.add-resource! w 0 :wood 5000)
     (world.add-resource! w 0 :stone 5000)
     (world.add-resource! w 0 :gold 5000)
     (world.set-player-age! w 0 (content.max-age))
     (let [before (world.resource-amount w 0 :wood)]
       (orders.issue! w (orders.advance-age 0))
       (sim.tick! w)
       (let [after (world.resource-amount w 0 :wood)]
         (luaunit.assertEquals after before)))))

 :test-age-bonuses-apply
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.set-player-age! w 0 1)
     (let [hp1 (world.effective-max-hp w 2)]
       (world.set-player-age! w 0 2)
       (let [hp2 (world.effective-max-hp w 2)]
         (luaunit.assertTrue (> hp2 hp1))))))

 :test-advancement-countdown
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :stone 500)
     (world.add-resource! w 0 :gold 500)
     (orders.issue! w (orders.advance-age 0))
     (sim.tick! w)
     (let [left (world.age-progress w 0)]
       (luaunit.assertNotNil left)
       (luaunit.assertTrue (> left 0)))))}
