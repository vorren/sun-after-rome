;; Test: Movement system
(local luaunit (require :luaunit))
(local world (require :src.world))
(local sim (require :src.sim))
(local orders (require :src.orders))
(local components (require :src.components))

{:test-move-command
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     ;; Set up the task manually to test movement
     (let [t (world.world-get w 1 :task)]
       (set t.kind :move)
       (set t.tx 10)
       (set t.ty 10))
     (let [pos (world.world-get w 1 :position)]
       (sim.tick! w)
       ;; Unit should have moved toward (10,10)
       (luaunit.assertTrue (or (> pos.x 4) (> pos.y 4))))))}
