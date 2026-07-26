;; Test: World creation and entity lifecycle
(local luaunit (require :luaunit))
(local world (require :src.world))
(local content (require :src.content))

{:test-make-world
 (fn []
   (let [w (world.make-world {:width 10 :height 8 :players 2 :seed 42})]
     (luaunit.assertEquals w.width 10)
     (luaunit.assertEquals w.height 8)
     (luaunit.assertEquals w.num-players 2)
     (luaunit.assertEquals w.tick 0)
     (luaunit.assertEquals w.next-id 1)))

 :test-spawn-entity
 (fn []
   (let [w (world.make-world {:seed 42})
         id (world.spawn! w :villager {:owner 0 :x 5 :y 5})]
     (luaunit.assertNotNil id)
     (luaunit.assertTrue (world.world-has? w id :kind))
     (luaunit.assertTrue (world.world-has? w id :position))
     (luaunit.assertTrue (world.world-has? w id :owner))
     (luaunit.assertTrue (world.world-has? w id :health))
     (luaunit.assertTrue (world.world-has? w id :carry))
     (luaunit.assertTrue (world.world-has? w id :task))))

 :test-remove-entity
 (fn []
   (let [w (world.make-world {:seed 42})
         id (world.spawn! w :villager {:owner 0 :x 5 :y 5})]
     (luaunit.assertTrue (world.world-has? w id :kind))
     (world.world-remove-entity! w id)
     (luaunit.assertFalse (world.world-has? w id :kind))))

 :test-world-query-sorted
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :villager {:owner 0 :x 1 :y 1})
     (world.spawn! w :villager {:owner 0 :x 2 :y 2})
     (world.spawn! w :villager {:owner 0 :x 3 :y 3})
     (let [q (world.world-query w :kind)]
       (luaunit.assertEquals (# q) 3)
       ;; Verify sorted by eid
       (luaunit.assertTrue (< (. q 1 :eid) (. q 2 :eid)))
       (luaunit.assertTrue (< (. q 2 :eid) (. q 3 :eid))))))

 :test-resources
 (fn []
   (let [w (world.make-world {:seed 42})]
     (luaunit.assertEquals (world.resource-amount w 1 :wood) 0)
     (world.add-resource! w 1 :wood 100)
     (luaunit.assertEquals (world.resource-amount w 1 :wood) 100)
     (luaunit.assertTrue (world.can-afford? w 1 {:wood 50}))
     (luaunit.assertFalse (world.can-afford? w 1 {:wood 150}))
     (world.pay! w 1 {:wood 30})
     (luaunit.assertEquals (world.resource-amount w 1 :wood) 70)))}
