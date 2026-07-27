;; Test: Production system
(local luaunit (require :luaunit))
(local world (require :src.world))
(local sim (require :src.sim))
(local orders (require :src.orders))
(local content (require :src.content))

{:test-training-produces-unit
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :barracks {:owner 0 :x 5 :y 3})
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.add-resource! w 0 :wood 200)
     (world.add-resource! w 0 :gold 200)
     (world.add-resource! w 0 :stone 200)
     (let [before (# (world.world-entities w))]
       (orders.issue! w (orders.train 1 :knight))
       (sim.run! w (+ (content.train-time :knight) 5))
       (let [after (# (world.world-entities w))]
         (luaunit.assertTrue (> after before))))))

 :test-fifo-queue-order
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :barracks {:owner 0 :x 5 :y 3})
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (orders.issue! w (orders.train 1 :pikeman))
     (orders.issue! w (orders.train 1 :knight))
     (sim.run! w (+ (content.train-time :knight) 2))
     (let [prod (world.world-get w 1 :producer)]
       (luaunit.assertEquals (. prod.queue 1) :pikeman))))

 :test-wrong-building-rejection
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (let [before (# (world.world-entities w))]
       (orders.issue! w (orders.train 1 :knight))
       (sim.run! w 5)
       (let [after (# (world.world-entities w))]
         (luaunit.assertEquals after before)))))

 :test-train-time-countdown
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :barracks {:owner 0 :x 5 :y 3})
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.add-resource! w 0 :wood 200)
     (world.add-resource! w 0 :gold 200)
     (world.add-resource! w 0 :stone 200)
     (orders.issue! w (orders.train 1 :knight))
     (let [prod (world.world-get w 1 :producer)]
       (luaunit.assertEquals prod.progress 0))
     (sim.tick! w)
     (let [prod (world.world-get w 1 :producer)]
       (luaunit.assertTrue (> prod.progress 0)))))

 :test-cost-deduction-at-order
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :barracks {:owner 0 :x 5 :y 3})
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.add-resource! w 0 :wood 100)
     (world.add-resource! w 0 :gold 100)
     (world.add-resource! w 0 :stone 100)
     (let [cost (content.unit-cost :knight)
           before-wood (world.resource-amount w 0 :wood)]
       (orders.issue! w (orders.train 1 :knight))
       (sim.tick! w)
       (let [after-wood (world.resource-amount w 0 :wood)]
         (luaunit.assertEquals after-wood (- before-wood (or cost.wood 0)))))))}
