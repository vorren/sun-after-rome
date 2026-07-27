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
         (luaunit.assertTrue (> after before))))))}
