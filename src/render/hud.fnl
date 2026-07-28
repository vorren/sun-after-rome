;; aurelius.render.hud --- HUD overlay with group selection, command hotkeys, cursor changes.

(local world (require :src.world))
(local content (require :src.content))
(local iso (require :src.render.iso))
(local orders (require :src.orders))
(local floating-text (require :src.render.floating-text))

(var selected-eids [])
(var command-mode nil)
(var drag-start nil)
(var cursor-default nil)
(var cursor-pointer nil)
(var cursor-crosshair nil)
(var cursor-hand nil)

(fn init-cursors []
  (set cursor-default (love.mouse.getSystemCursor "arrow"))
  (set cursor-pointer (love.mouse.getSystemCursor "hand"))
  (set cursor-crosshair (love.mouse.getSystemCursor "crosshair"))
  (set cursor-hand (love.mouse.getSystemCursor "hand")))

(fn set-selection! [eid] (set selected-eids [eid]))
(fn get-selection [] selected-eids)
(fn add-to-selection [eid]
  (var found false)
  (each [_ e (ipairs selected-eids)]
    (when (= e eid) (set found true)))
  (when (not found) (table.insert selected-eids eid)))
(fn remove-from-selection [eid]
  (var i 1)
  (while (<= i (# selected-eids))
    (if (= (. selected-eids i) eid)
        (table.remove selected-eids i)
        (set i (+ i 1)))))
(fn set-command-mode [mode] (set command-mode mode))
(fn get-command-mode [] command-mode)
(fn set-drag-start [x y] (set drag-start {:x x :y y}))
(fn get-drag-start [] drag-start)
(fn clear-drag-start [] (set drag-start nil))

(fn entity-at-tile [w tile-x tile-y]
  (var best nil)
  (var bd nil)
  (each [_ pair (ipairs (world.world-query w :position))]
    (let [eid pair.eid pos pair.val
          d (+ (math.abs (- pos.x tile-x)) (math.abs (- pos.y tile-y)))]
      (when (or (= bd nil) (< d bd))
        (set best eid)
        (set bd d))))
  (when (and best (<= bd 2)) best))

(fn entities-in-rect [w x1 y1 x2 y2]
  (let [min-x (math.min x1 x2) max-x (math.max x1 x2)
        min-y (math.min y1 y2) max-y (math.max y1 y2)
        result []]
    (each [_ pair (ipairs (world.world-query w :position))]
      (let [eid pair.eid pos pair.val owner (world.world-get w eid :owner)]
        (when (and owner (= owner.player 0)
                   (>= pos.x min-x) (<= pos.x max-x)
                   (>= pos.y min-y) (<= pos.y max-y))
          (table.insert result eid))))
    result))

(fn tile-at-screen [screen-x screen-y]
  (let [tile-w 64 tile-h 32 offset-x 640 offset-y 100
        (raw-tx raw-ty) (iso.to-tile (- screen-x offset-x) (- screen-y offset-y) tile-w tile-h)]
    (values (math.floor (+ raw-tx 0.5))
            (math.floor (+ raw-ty 0.5)))))

(fn classify-target [w eid]
  (when eid
    (let [kind (world.world-get w eid :kind)
          owner (world.world-get w eid :owner)
          node (world.world-get w eid :node)]
      (when kind
        (if node :resource
            (and owner (not= owner.player 0)) :enemy
            (and owner kind (= owner.player 0))
            (if (> (content.kind-stat kind.tag :damage 0) 0) :unit :building)
            :neutral)))))

(fn issue-gather [w eid target]
  (when (world.world-get w target :position)
    (orders.issue! w (orders.gather eid target))
    (floating-text.add-text w eid "Gather")))

(fn issue-attack [w eid target]
  (when (world.world-get w target :position)
    (orders.issue! w (orders.attack eid target))
    (floating-text.add-text w eid "Attack")))

(fn issue-move [w eid tx ty]
  (orders.issue! w (orders.move eid tx ty))
  (floating-text.add-text w eid "Move"))

(fn issue-command-to-selected [w x y]
  (let [(tile-x tile-y) (tile-at-screen x y)
        target (entity-at-tile w tile-x tile-y)]
    (each [_ eid (ipairs selected-eids)]
      (if (= command-mode :gather)
          (when target (issue-gather w eid target))
          (= command-mode :attack)
          (when target (issue-attack w eid target))
          true
          (issue-move w eid tile-x tile-y)))))

(fn handle-command-click [x y w]
  (when (> (# selected-eids) 0)
    (issue-command-to-selected w x y)
    (set command-mode nil)))

(fn handle-right-click [x y w]
  (when (> (# selected-eids) 0)
    (let [(tile-x tile-y) (tile-at-screen x y)
          target (entity-at-tile w tile-x tile-y)
          target-type (classify-target w target)]
      (each [_ eid (ipairs selected-eids)]
        (if (= target-type :resource) (issue-gather w eid target)
            (= target-type :enemy) (issue-attack w eid target)
            true (issue-move w eid tile-x tile-y))))))

(fn handle-mouse-move [x y w]
  (when cursor-default
    (let [(tile-x tile-y) (tile-at-screen x y)
          eid (entity-at-tile w tile-x tile-y)
          target-type (when eid (classify-target w eid))]
      (if command-mode
          (love.mouse.setCursor cursor-crosshair)
          (= target-type :resource)
          (love.mouse.setCursor cursor-hand)
          (= target-type :enemy)
          (love.mouse.setCursor cursor-crosshair)
          eid
          (love.mouse.setCursor cursor-pointer)
          true
          (love.mouse.setCursor cursor-default)))))

(fn draw-selection-highlight [w]
  (each [_ eid (ipairs selected-eids)]
    (let [pos (world.world-get w eid :position)
          kind (world.world-get w eid :kind)]
      (when (and pos kind)
        (let [tile-w 64 tile-h 32 offset-x 640 offset-y 100
              (sx sy) (iso.to-screen pos.x pos.y tile-w tile-h)
              screen-x (+ sx offset-x) screen-y (+ sy offset-y)]
          (love.graphics.setColor 0.2 1 0.2 0.8)
          (love.graphics.setLineWidth 2)
          (love.graphics.ellipse "line" screen-x screen-y (* tile-w 0.6) (* tile-h 0.6))
          (love.graphics.setLineWidth 1)
          (love.graphics.setColor 1 1 1 1))))))

(fn draw-drag-rect []
  (when drag-start
    (let [mx (love.mouse.getX) my (love.mouse.getY)]
      (love.graphics.setColor 0.2 1 0.2 0.3)
      (love.graphics.rectangle "fill"
        (math.min drag-start.x mx) (math.min drag-start.y my)
        (math.abs (- mx drag-start.x)) (math.abs (- my drag-start.y)))
      (love.graphics.setColor 0.2 1 0.2 0.8)
      (love.graphics.setLineWidth 1)
      (love.graphics.rectangle "line"
        (math.min drag-start.x mx) (math.min drag-start.y my)
        (math.abs (- mx drag-start.x)) (math.abs (- my drag-start.y))))))

(fn draw-hud [w]
  (love.graphics.setColor 1 1 1)
  (love.graphics.print "=== Sun After Rome ===" 10 10)
  (love.graphics.print (.. "Tick: " w.tick) 10 30)
  (for [p 1 w.num-players]
    (let [pl (- p 1)
          wood (world.resource-amount w pl :wood)
          gold (world.resource-amount w pl :gold)
          stone (world.resource-amount w pl :stone)
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
  (when (> (# selected-eids) 0)
    (love.graphics.setColor 1 1 0)
    (love.graphics.print (.. "Selected: " (# selected-eids) " units") 10 (- w.height 80))
    (let [eid (. selected-eids 1)
          kind (world.world-get w eid :kind)
          task (world.world-get w eid :task)]
      (when kind (love.graphics.print (.. "Type: " (tostring kind.tag)) 200 (- w.height 80)))
      (when task (love.graphics.print (.. "Task: " (tostring task.kind)) 400 (- w.height 80)))))
  (when command-mode
    (love.graphics.setColor 1 0.5 0)
    (love.graphics.print (.. "Mode: " (string.upper (tostring command-mode)) " - click target") 10 (- w.height 60))))

(fn handle-click [x y w button shift]
  (if (= button 1)
      (if command-mode
          (handle-command-click x y w)
          (let [(tile-x tile-y) (tile-at-screen x y)
                eid (entity-at-tile w tile-x tile-y)]
            (if shift
                (when eid
                  (if (> (# selected-eids) 0)
                      (remove-from-selection eid)
                      (add-to-selection eid)))
                (if eid (set-selection! eid) (set selected-eids [])))))
      (= button 2) (handle-right-click x y w)))

{: draw-hud : handle-click : set-selection! : get-selection : draw-selection-highlight
 : set-command-mode : get-command-mode : set-drag-start : get-drag-start : clear-drag-start
 : entities-in-rect : add-to-selection : remove-from-selection : draw-drag-rect
 : init-cursors : handle-mouse-move}
