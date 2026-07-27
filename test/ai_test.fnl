;; Test: AI controller system
(local luaunit (require :luaunit))
(local world (require :src.world))
(local sim (require :src.sim))
(local orders (require :src.orders))
(local content (require :src.content))
(local ai (require :src.ai.scripted))
(local personalities (require :src.ai.personalities))

{:test-ai-creates-orders
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.add-resource! w 0 :wood 200)
     (world.add-resource! w 0 :gold 200)
     (world.add-resource! w 0 :stone 200)
     (world.set-controller! w 0 (ai.make-ai-controller 0))
     (ai.ai-system w 0)
     (luaunit.assertTrue (> (# w.orders) 0))))

 :test-ai-trains-villagers
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (ai.ai-system w 0)
     (var found-train false)
     (each [_ o (ipairs w.orders)]
       (when (and (= o.tag :train) (= o.unit :villager))
         (set found-train true)))
     (luaunit.assertTrue found-train)))

 :test-ai-does-not-overtrain
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (for [_ 1 6]
       (world.spawn! w :villager {:owner 0 :x 4 :y 4}))
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (ai.ai-system w 0)
     (var found-train false)
     (each [_ o (ipairs w.orders)]
       (when (and (= o.tag :train) (= o.unit :villager))
         (set found-train true)))
     (luaunit.assertFalse found-train)))

 :test-ai-advances-age
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (luaunit.assertEquals (world.player-age w 0) 1)
     (ai.ai-system w 0)
     (var found-advance false)
     (each [_ o (ipairs w.orders)]
       (when (= o.tag :advance-age)
         (set found-advance true)))
     (luaunit.assertTrue found-advance)))

 :test-ai-does-not-advance-if-cannot-afford
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (ai.ai-system w 0)
     (var found-advance false)
     (each [_ o (ipairs w.orders)]
       (when (= o.tag :advance-age)
         (set found-advance true)))
     (luaunit.assertFalse found-advance)))

 :test-ai-attacks-enemy
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :knight {:owner 0 :x 5 :y 5})
     (world.spawn! w :villager {:owner 1 :x 10 :y 10})
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (ai.ai-system w 0)
     (var found-attack false)
     (each [_ o (ipairs w.orders)]
       (when (= o.tag :attack)
         (set found-attack true)))
     (luaunit.assertTrue found-attack)))

 :test-ai-deterministic
 (fn []
   (let [w1 (world.make-world {:seed 42})
         w2 (world.make-world {:seed 42})]
     (each [_ w (ipairs [w1 w2])]
       (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
       (world.spawn! w :villager {:owner 0 :x 4 :y 4})
       (world.add-resource! w 0 :wood 200)
       (world.add-resource! w 0 :gold 200)
       (world.add-resource! w 0 :stone 200))
     (ai.ai-system w1 0)
     (ai.ai-system w2 0)
     (luaunit.assertEquals (# w1.orders) (# w2.orders))
     (for [i 1 (# w1.orders)]
       (let [o1 (. w1.orders i)
             o2 (. w2.orders i)]
         (luaunit.assertEquals o1.tag o2.tag)
         (luaunit.assertEquals o1.eid o2.eid)))))

 :test-ai-controller-structure
 (fn []
   (let [ctrl (ai.make-ai-controller 0)]
     (luaunit.assertEquals ctrl.type :ai)
     (luaunit.assertEquals ctrl.faction 0)
     (luaunit.assertNotNil ctrl.tick)
     (luaunit.assertNotNil ctrl.personality)))

 :test-faction-entities
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.spawn! w :town-centre {:owner 1 :x 20 :y 12})
     (let [ents (ai.faction-entities w 0)]
       (luaunit.assertEquals (# ents) 2))
     (let [ents (ai.faction-entities w 1)]
       (luaunit.assertEquals (# ents) 1))))

 :test-has-building
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (luaunit.assertTrue (ai.has-building? w 0 :town-centre))
     (luaunit.assertFalse (ai.has-building? w 0 :barracks))
     (luaunit.assertFalse (ai.has-building? w 1 :town-centre))))

 :test-personality-villager-target
 (fn []
   (let [aggressive (personalities.get-personality :aggressive)
         defensive (personalities.get-personality :defensive)]
     (luaunit.assertEquals aggressive.villager-target 6)
     (luaunit.assertEquals defensive.villager-target 8)))

 :test-ai-uses-personality-villager-target
 (fn []
   (let [w (world.make-world {:seed 42})
         defensive (personalities.get-personality :defensive)]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (for [_ 1 7]
       (world.spawn! w :villager {:owner 0 :x 4 :y 4}))
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (ai.ai-system w 0 defensive)
     (var found-train false)
     (each [_ o (ipairs w.orders)]
       (when (and (= o.tag :train) (= o.unit :villager))
         (set found-train true)))
     (luaunit.assertTrue found-train)))

 :test-ai-respects-military-threshold
 (fn []
   (let [w (world.make-world {:seed 42})
         aggressive (personalities.get-personality :aggressive)]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :barracks {:owner 0 :x 5 :y 5})
     (for [_ 1 2]
       (world.spawn! w :knight {:owner 0 :x 6 :y 6}))
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (ai.ai-system w 0 aggressive)
     (var found-train false)
     (each [_ o (ipairs w.orders)]
       (when (and (= o.tag :train) (= o.unit :knight))
         (set found-train true)))
     (luaunit.assertTrue found-train)))

 :test-ai-does-not-overtrain-military
 (fn []
   (let [w (world.make-world {:seed 42})
         aggressive (personalities.get-personality :aggressive)]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :barracks {:owner 0 :x 5 :y 5})
     (for [_ 1 3]
       (world.spawn! w :knight {:owner 0 :x 6 :y 6}))
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (ai.ai-system w 0 aggressive)
     (var found-train false)
     (each [_ o (ipairs w.orders)]
       (when (and (= o.tag :train) (= o.unit :knight))
         (set found-train true)))
     (luaunit.assertFalse found-train)))

 :test-ai-respects-attack-when-idle
 (fn []
   (let [w (world.make-world {:seed 42})
         defensive (personalities.get-personality :defensive)]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :knight {:owner 0 :x 5 :y 5})
     (world.spawn! w :villager {:owner 1 :x 10 :y 10})
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (ai.ai-system w 0 defensive)
     (var found-attack false)
     (each [_ o (ipairs w.orders)]
       (when (= o.tag :attack)
         (set found-attack true)))
     (luaunit.assertFalse found-attack)))

 :test-ai-takeover-creates-controller
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (sim.take-player! w 0)
     (let [ctrl (world.get-controller w 0)]
       (luaunit.assertEquals ctrl.type :ai)
       (luaunit.assertNotNil ctrl.tick)
       (luaunit.assertNotNil ctrl.personality))))

 :test-ai-takeover-issues-orders
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :gold 500)
     (world.add-resource! w 0 :stone 500)
     (sim.take-player! w 0)
     (sim.tick! w)
     (sim.tick! w)
     (luaunit.assertTrue (> (# w.log) 0))))}
