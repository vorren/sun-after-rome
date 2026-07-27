;; aurelius.render.hud --- HUD overlay: resources, age, selected entity.

(local world (require :src.world))
(local content (require :src.content))

(var selected-eid nil)

(fn set-selection! [eid]
  (set selected-eid eid))

(fn draw-hud [w]
  ;; Resource display for player 1
  (love.graphics.setColor 1 1 1)
  (love.graphics.print "=== Sun After Rome ===" 10 10)
  (love.graphics.print (.. "Tick: " w.tick) 10 30)
  ;; Player 1 resources
  (for [p 1 w.num-players]
    (let [pl (- p 1)
          wood (world.resource-amount w pl :wood)
          food (world.resource-amount w pl :food)
          stone (world.resource-amount w pl :stone)
          gold (world.resource-amount w pl :gold)
          age (world.player-age w pl)
          y (+ 50 (* (- p 1) 80))]
      (love.graphics.setColor 0.8 0.8 0.8)
      (love.graphics.print (.. "Player " p " (Age " age ")") 10 y)
      (love.graphics.setColor 0.4 0.8 0.2)
      (love.graphics.print (.. "Wood: " wood) 10 (+ y 18))
      (love.graphics.setColor 0.8 0.8 0.3)
      (love.graphics.print (.. "Gold: " gold) 120 (+ y 18))
      (love.graphics.setColor 0.6 0.6 0.6)
      (love.graphics.print (.. "Stone: " stone) 230 (+ y 18))
      ;; Age progress
      (let [prog (world.age-progress w pl)]
        (when prog
          (love.graphics.setColor 0.5 0.8 1)
          (love.graphics.print (.. "Advancing... " prog " ticks left") 10 (+ y 36))))))
  ;; Selected entity
  (when selected-eid
    (let [kind (world.world-get w selected-eid :kind)
          health (world.world-get w selected-eid :health)
          pos (world.world-get w selected-eid :position)
          task (world.world-get w selected-eid :task)]
      (when kind
        (love.graphics.setColor 1 1 0)
        (love.graphics.print (.. "Selected: " (tostring kind.tag)) 10 (- w.height 80))
        (when health
          (love.graphics.print (.. "HP: " health.hp) 200 (- w.height 80)))
        (when pos
          (love.graphics.print (.. "Pos: " pos.x "," pos.y) 300 (- w.height 80)))
        (when task
          (love.graphics.print (.. "Task: " (tostring task.kind)) 450 (- w.height 80)))))))

(fn handle-click [x y w]
  ;; Simple: find entity nearest to click in tile coords
  (let [tile-w 64
        tile-h 32
        tile-x (/ (- x 640) (/ tile-w 2))
        tile-y (/ (- y 100) (/ tile-h 2))]
    (var best nil)
    (var bd nil)
    (each [_ pair (ipairs (world.world-query w :position))]
      (let [eid pair.eid
            pos pair.val
            d (math.abs (+ (math.abs (- pos.x tile-x)) (math.abs (- pos.y tile-y))))]
        (when (or (= bd nil) (< d bd))
          (set best eid)
          (set bd d))))
    (when (and best (< bd 3))
      (set-selection! best))))

{: draw-hud : handle-click : set-selection!}
