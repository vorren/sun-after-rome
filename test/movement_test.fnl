;; Test: Movement system
(local luaunit (require :luaunit))
(local world (require :src.world))
(local sim (require :src.sim))
(local orders (require :src.orders))
(local components (require :src.components))
(local movement (require :src.systems.movement))

{:test-move-command
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :villager {:owner 0 :x 4 :y 4})
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (let [t (world.world-get w 1 :task)]
       (set t.kind :move)
       (set t.tx 10)
       (set t.ty 10))
     (let [pos (world.world-get w 1 :position)]
       (sim.tick! w)
       (luaunit.assertTrue (or (> pos.x 4) (> pos.y 4))))))

 :test-speed-scaling
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :villager {:owner 0 :x 0 :y 0})
     (world.spawn! w :knight {:owner 0 :x 0 :y 2})
     (let [t1 (world.world-get w 1 :task)
           t2 (world.world-get w 2 :task)]
       (set t1.kind :move) (set t1.tx 20) (set t1.ty 0)
       (set t2.kind :move) (set t2.tx 20) (set t2.ty 2))
     (sim.tick! w)
     (let [p1 (world.world-get w 1 :position)
           p2 (world.world-get w 2 :position)]
       (luaunit.assertTrue (> p2.x p1.x)))))

 :test-boundary-check
 (fn []
   (let [w (world.make-world {:seed 42 :width 10 :height 10})]
     (world.spawn! w :villager {:owner 0 :x 9 :y 9})
     (let [t (world.world-get w 1 :task)]
       (set t.kind :move)
       (set t.tx 20)
       (set t.ty 20))
     (sim.tick! w)
     (let [pos (world.world-get w 1 :position)]
       (luaunit.assertTrue (<= pos.x 10))
       (luaunit.assertTrue (<= pos.y 10)))))

 :test-idle-at-destination
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :villager {:owner 0 :x 5 :y 5})
     (let [t (world.world-get w 1 :task)]
       (set t.kind :move)
       (set t.tx 5)
       (set t.ty 5))
     (sim.tick! w)
     (let [t (world.world-get w 1 :task)]
       (luaunit.assertEquals t.kind :idle))))

 :test-units-pass-through-each-other
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :villager {:owner 0 :x 3 :y 3})
     (world.spawn! w :villager {:owner 1 :x 5 :y 3})
     (let [t1 (world.world-get w 1 :task)
           t2 (world.world-get w 2 :task)]
       (set t1.kind :move) (set t1.tx 8) (set t1.ty 3)
       (set t2.kind :move) (set t2.tx 1) (set t2.ty 3))
     (sim.tick! w)
     (let [p1 (world.world-get w 1 :position)
           p2 (world.world-get w 2 :position)]
       (luaunit.assertTrue (> p1.x 3))
       (luaunit.assertTrue (< p2.x 5)))))

 :test-movement-system-function
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :villager {:owner 0 :x 0 :y 0})
     (let [t (world.world-get w 1 :task)]
       (set t.kind :move)
       (set t.tx 3)
       (set t.ty 3))
     (movement.movement-system w)
     (let [pos (world.world-get w 1 :position)]
       (luaunit.assertTrue (> pos.x 0)))))}
