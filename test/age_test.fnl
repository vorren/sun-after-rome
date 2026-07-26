;; Test: Age advancement
(local luaunit (require :luaunit))
(local world (require :src.world))
(local content (require :src.content))

{:test-age-advancement
 (fn []
   (let [w (world.make-world {:seed 42})]
     (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
     (world.add-resource! w 0 :wood 500)
     (world.add-resource! w 0 :stone 500)
     (world.add-resource! w 0 :gold 500)
     (luaunit.assertEquals (world.player-age w 0) 1)
     ;; Start age advancement
     (world.set-age-progress! w 0 (content.age-time 2))
     ;; Tick until complete
     (for [_ 1 (content.age-time 2)]
       (set w.tick (+ w.tick 1))
       (let [left (world.age-progress w 0)]
         (when left
           (world.set-age-progress! w 0 (- left 1))
           (when (<= (world.age-progress w 0) 0)
             (world.set-player-age! w 0 2)
             (world.set-age-progress! w 0 nil)))))
     (luaunit.assertEquals (world.player-age w 0) 2)))}
