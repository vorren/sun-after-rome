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
       (luaunit.assertTrue (> wood 0)))))

 :test-node-depletion
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 3 :y 4})
     (let [tree (world.spawn! w :tree {:x 3 :y 5})]
       (world.world-get w tree :node)
       (let [node (world.world-get w tree :node)]
         (set node.amount 5))
       (orders.issue! w (orders.gather 2 tree))
       (sim.run! w 50)
       (luaunit.assertFalse (world.world-has? w tree :node)))))

 :test-multiple-resource-types
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.spawn! w :villager {:owner 0 :x 4 :y 5})
     (world.spawn! w :tree {:x 5 :y 4})
     (world.spawn! w :gold-mine {:x 5 :y 5})
     (orders.issue! w (orders.gather 2 4))
     (orders.issue! w (orders.gather 3 5))
     (sim.run! w 50)
     (let [wood (world.resource-amount w 0 :wood)
           gold (world.resource-amount w 0 :gold)]
       (luaunit.assertTrue (> wood 0))
       (luaunit.assertTrue (> gold 0)))))

 :test-capacity-full-goes-to-drop
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.spawn! w :tree {:x 5 :y 4})
     (let [t (world.world-get w 2 :task)]
       (set t.kind :gather)
       (set t.phase :gathering)
       (set t.target 3)
       (set t.tx 5)
       (set t.ty 4))
     (let [cargo (world.world-get w 2 :carry)]
       (set cargo.amount 10)
       (set cargo.resource :wood))
     (let [node (world.world-get w 3 :node)]
       (set node.amount 100))
     (let [gather (require :src.systems.gather)]
       (gather.gather-system w))
     (let [t (world.world-get w 2 :task)]
       (luaunit.assertEquals t.phase :to-drop))))

 :test-gather-system-function
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.spawn! w :tree {:x 5 :y 4})
     (let [t (world.world-get w 2 :task)]
       (set t.kind :gather)
       (set t.phase :gathering)
       (set t.target 3)
       (set t.tx 5)
       (set t.ty 4))
     (let [node (world.world-get w 3 :node)]
       (set node.amount 100))
     (let [gather (require :src.systems.gather)]
       (gather.gather-system w))
     (let [cargo (world.world-get w 2 :carry)]
       (luaunit.assertTrue (> cargo.amount 0)))))}
