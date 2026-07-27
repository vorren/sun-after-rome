;; aurelius.render.hud --- HUD overlay: resources, age, selected entity, selection highlight.

(local world (require :src.world))
(local content (require :src.content))
(local iso (require :src.render.iso))

(var selected-eid nil)

(fn set-selection! [eid]
  (set selected-eid eid))

(fn get-selection [] selected-eid)

(fn entity-at-tile [w tile-x tile-y]
  (var best nil)
  (var bd nil)
  (each [_ pair (ipairs (world.world-query w :position))]
    (let [eid pair.eid
          pos pair.val
          d (+ (math.abs (- pos.x tile-x)) (math.abs (- pos.y tile-y)))]
      (when (or (= bd nil) (< d bd))
        (set best eid)
        (set bd d))))
  (when (and best (<= bd 2))
    best))

(fn tile-at-screen [screen-x screen-y]
  (let [tile-w 64
        tile-h 32
        offset-x 640
        offset-y 100]
    (iso.to-tile (- screen-x offset-x) (- screen-y offset-y) tile-w tile-h)))

(fn classify-target [w eid]
  (when eid
    (let [kind (world.world-get w eid :kind)
          owner (world.world-get w eid :owner)
          node (world.world-get w eid :node)]
      (when kind
        (if
          node :resource
          (and owner (not= owner.player 0)) :enemy
          (and owner kind (= owner.player 0))
          (if (> (content.kind-stat kind.tag :damage 0) 0) :unit :building)
          :neutral)))))

(fn issue-gather [w eid target]
  (let [t (world.world-get w eid :task)]
    (when t
      (let [node-pos (world.world-get w target :position)]
        (set t.kind :gather)
        (set t.phase :to-node)
        (set t.target target)
        (when node-pos
          (set t.tx node-pos.x)
          (set t.ty node-pos.y))))))

(fn issue-attack [w eid target]
  (let [t (world.world-get w eid :task)]
    (when t
      (let [target-pos (world.world-get w target :position)]
        (set t.kind :attack)
        (set t.phase nil)
        (set t.target target)
        (when target-pos
          (set t.tx target-pos.x)
          (set t.ty target-pos.y))))))

(fn issue-move [w eid tx ty]
  (let [t (world.world-get w eid :task)]
    (when t
      (set t.kind :move)
      (set t.phase nil)
      (set t.target nil)
      (set t.tx tx)
      (set t.ty ty))))

(fn handle-right-click [x y w]
  (when selected-eid
    (let [(tile-x tile-y) (tile-at-screen x y)
          target (entity-at-tile w tile-x tile-y)
          target-type (classify-target w target)]
      (if
        (= target-type :resource) (issue-gather w selected-eid target)
        (= target-type :enemy) (issue-attack w selected-eid target)
        true (issue-move w selected-eid tile-x tile-y)))))

(fn draw-selection-highlight [w]
  (when selected-eid
    (let [pos (world.world-get w selected-eid :position)
          kind (world.world-get w selected-eid :kind)]
      (when (and pos kind)
        (let [tile-w 64
              tile-h 32
              offset-x 640
              offset-y 100
              (sx sy) (iso.to-screen pos.x pos.y tile-w tile-h)
              screen-x (+ sx offset-x)
              screen-y (+ sy offset-y)]
          (love.graphics.setColor 0.2 1 0.2 0.8)
          (love.graphics.set-line-width 2)
          (love.graphics.ellipse "line" screen-y screen-x (* tile-w 0.6) (* tile-h 0.6))
          (love.graphics.set-line-width 1)
          (love.graphics.setColor 1 1 1 1))))))

(fn draw-hud [w]
  (love.graphics.setColor 1 1 1)
  (love.graphics.print "=== Sun After Rome ===" 10 10)
  (love.graphics.print (.. "Tick: " w.tick) 10 30)
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
      (let [prog (world.age-progress w pl)]
        (when prog
          (love.graphics.setColor 0.5 0.8 1)
          (love.graphics.print (.. "Advancing... " prog " ticks left") 10 (+ y 36))))))
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

(fn handle-click [x y w button]
  (if
    (= button 1)
    (let [(tile-x tile-y) (tile-at-screen x y)
          eid (entity-at-tile w tile-x tile-y)]
      (set-selection! eid))
    (= button 2)
    (handle-right-click x y w)))

{: draw-hud : handle-click : set-selection! : get-selection : draw-selection-highlight}
