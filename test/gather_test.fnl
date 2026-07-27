;; Test: Gathering system
(local luaunit (require :luaunit))
(local world (require :src.world))
(local sim (require :src.sim))
(local orders (require :src.orders))

{:test-gather-deposits-resources
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.spawn! w :tree {:x 5 :y 4})
      (orders.issue! w (orders.gather 2 3))
     (sim.run! w 40)
     (let [wood (world.resource-amount w 0 :wood)]
       (luaunit.assertTrue (> wood 0)))))}
