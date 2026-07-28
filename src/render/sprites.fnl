;; aurelius.render.sprites --- sprite rendering with interpolation.
;; Loads actual sprites for villagers, falls back to colored circles for other units.

(local world (require :src.world))
(local iso (require :src.render.iso))
(local interpolation (require :src.render.interpolation))
(local camera (require :src.render.camera))
(local sprite-sheet (require :src.render.sprite-sheet))
(local animation (require :src.render.animation))
(local log (require :src.log))

(local tile-w 64)
(local tile-h 32)

;; Colored circles for units without sprites
(local unit-colors
  {:villager [0.2 0.8 0.2]
   :knight   [0.8 0.2 0.2]
   :pikeman  [0.2 0.2 0.8]
   :archer   [0.8 0.8 0.2]})

(local building-colors
  {:town-centre [0.6 0.4 0.2]
   :barracks    [0.5 0.5 0.5]})

(local node-colors
  {:tree       [0.1 0.5 0.1]
   :gold-mine  [0.9 0.8 0.1]
   :stone-mine [0.6 0.6 0.6]})

(var grid-visible true)

;; Sprite animations cache (entity-id -> animation)
(var entity-animations {})

;; Loaded sprite sheets
(var villager-walk-no-wood nil)
(var villager-walk-wood nil)

(fn load-villager-sprites []
  "Load villager walk sprites."
  (when (not villager-walk-no-wood)
    (set villager-walk-no-wood
         (sprite-sheet.load-animation
           "assets/units/Villager/Male/Woodcutter/Walk/Carrying no Wood"
           "Villagerwalk"
           75))
    (log.info :sprites "Loaded villager walk sprites (no wood)"))
  (when (not villager-walk-wood)
    (set villager-walk-wood
         (sprite-sheet.load-animation
           "assets/units/Villager/Male/Woodcutter/Walk/Carrying Wood"
           "Villagerwalk"
           75))
    (log.info :sprites "Loaded villager walk sprites (with wood)")))

(fn get-or-create-animation [eid tag task]
  "Get existing animation or create new one for entity."
  (or (. entity-animations eid)
      (let [sprites (if (and task
                             (= tag :villager)
                             (or (= task.kind :gather)
                                 (= task.kind :move)))
                        (if (and task task.target)
                            villager-walk-wood
                            villager-walk-no-wood)
                        nil)
            anim (when sprites
                   (animation.make-animation sprites 15 true))]
        (when anim
          (tset entity-animations eid anim))
        anim)))

(fn entity-direction [w eid]
  "Determine which direction set (0-4) to use based on entity movement."
  (let [task (world.world-get w eid :task)
        pos (world.world-get w eid :position)]
    ;; default to south (0) if no task or not moving
    (if (or (not task) (not= task.kind :move) (not task.tx) (not task.ty))
        0
        ;; calculate direction from movement
        (let [dx (- task.tx (or pos.x 0))
              dy (- task.ty (or pos.y 0))]
          (if (and (<= (math.abs dx) 0.1) (<= (math.abs dy) 0.1))
              0  ;; stationary, face south
              ;; determine direction based on angle
              (let [angle (math.atan2 dy dx)]
                ;; south (down) = 0, south-west = 1, west = 2, north-west = 3, north = 4
                (if (<= angle -2.4) 0      ;; south (near -pi)
                    (<= angle -0.7) 1      ;; south-west
                    (<= angle 0) 2         ;; west
                    (<= angle 0.7) 3       ;; north-west
                    4)))))))                ;; north

(fn toggle-grid []
  (set grid-visible (not grid-visible)))

(fn get-color [tag]
  (or (. unit-colors tag)
      (. building-colors tag)
      (. node-colors tag)
      [0.5 0.5 0.5]))

(fn health-bar-color [ratio]
  "Get color based on health ratio (0-1). Green → yellow → red."
  (if (>= ratio 0.6)
      [0.2 0.8 0.2]    ;; green
      (>= ratio 0.3)
      [0.9 0.9 0.2]    ;; yellow
      [0.9 0.2 0.2]))  ;; red

(fn draw-health-bar [w eid sx sy]
  "Draw health bar above entity at screen position (sx, sy)."
  (let [health (world.world-get w eid :health)
        kind (world.world-get w eid :kind)]
    (when (and health kind)
      (let [max-hp (world.effective-max-hp w eid)
            ratio (/ health.hp max-hp)]
        (when (< ratio 1)
          (let [bar-w 24
                bar-h 4
                bar-x (- sx (/ bar-w 2))
                bar-y (- sy 20)
                fill-w (* bar-w ratio)
                color (health-bar-color ratio)]
            ;; background
            (love.graphics.setColor 0.2 0.15 0.1)
            (love.graphics.rectangle :fill bar-x bar-y bar-w bar-h)
            ;; fill
            (love.graphics.setColor (. color 1) (. color 2) (. color 3))
            (love.graphics.rectangle :fill bar-x bar-y fill-w bar-h)))))))

(fn draw-idle-indicator [w eid sx sy]
  "Draw idle indicator above unit (flashing circle)."
  (let [task (world.world-get w eid :task)
        owner (world.world-get w eid :owner)]
    (when (and task
               (= task.kind :idle)
               owner
               (= owner.player 0))
      ;; flash based on tick
      (let [flash (math.floor (/ (or w.tick 0) 10))
            alpha (if (= (% flash 2) 0) 0.8 0.3)]
        (love.graphics.setColor 1 0.8 0 alpha)
        (love.graphics.circle :fill sx (- sy 20) 4)))))

(fn draw-entity [w eid]
  (let [kind (world.world-get w eid :kind)
        pos (interpolation.interpolated-pos w eid)]
    (when (and kind pos)
      (let [tag kind.tag
            (raw-sx raw-sy) (iso.to-screen pos.x pos.y tile-w tile-h)
            (offset-x offset-y) (camera.get-offset)
            sx (+ raw-sx offset-x)
            sy (+ raw-sy offset-y)
            task (world.world-get w eid :task)
            anim (get-or-create-animation eid tag task)]
        (if anim
            ;; draw with actual sprite
            (do
              (animation.update anim (/ 1 60))  ;; assuming 60fps
              (let [dir (entity-direction w eid)
                    sprite (animation.get-sprite anim dir)]
                (when sprite.image
                  (love.graphics.setColor 1 1 1)
                  (if sprite.mirror
                      ;; draw mirrored
                      (do
                        (love.graphics.draw sprite.image
                                           (+ sx 32) sy
                                           0 -1 1 32 0))
                      ;; draw normal
                      (love.graphics.draw sprite.image
                                         (- sx 32) sy
                                         0 1 1 0 0)))))
            ;; fallback to colored circle/rectangle
            (let [color (. (get-color tag) 1)
                  color2 (. (get-color tag) 2)
                  color3 (. (get-color tag) 3)]
              (if (. building-colors tag)
                  (do
                    (love.graphics.setColor color color2 color3)
                    (love.graphics.rectangle :fill (- sx 24) (- sy 32) 48 64)
                    (love.graphics.setColor 0 0 0)
                    (love.graphics.rectangle :line (- sx 24) (- sy 32) 48 64))
                  (do
                    (love.graphics.setColor color color2 color3)
                    (love.graphics.circle :fill sx (- sy 8) 8)
                    (love.graphics.setColor 0 0 0)
                    (love.graphics.circle :line sx (- sy 8) 8)))))
        ;; draw health bar above entity
        (draw-health-bar w eid sx sy)
        ;; draw idle indicator
        (draw-idle-indicator w eid sx sy)))))

(fn draw-isometric-grid [w]
  (when grid-visible
    (let [(offset-x offset-y) (camera.get-offset)]
      (love.graphics.setColor 0.3 0.3 0.3 0.3)
      (for [x 0 (- w.width 1)]
        (for [y 0 (- w.height 1)]
          (let [(raw-sx raw-sy) (iso.to-screen x y tile-w tile-h)]
            (var sx (+ raw-sx offset-x))
            (var sy (+ raw-sy offset-y))
            (love.graphics.line
             sx (- sy (/ tile-h 2))
             (+ sx (/ tile-w 2)) sy
             sx (+ sy (/ tile-h 2))
             (- sx (/ tile-w 2)) sy
             sx (- sy (/ tile-h 2)))))))))

(fn draw-world [w]
  ;; load sprites on first draw
  (load-villager-sprites)
  (draw-isometric-grid w)
  (let [entities []]
    (each [_ pair (ipairs (world.world-query w :kind))]
      (let [eid pair.eid
            pos (world.world-get w eid :position)]
        (when pos
          (table.insert entities {:eid eid
                                  :depth (iso.depth-key pos.x pos.y)}))))
    (table.sort entities (fn [a b]
                           (if (= a.depth b.depth)
                               (< a.eid b.eid)
                               (< a.depth b.depth))))
    (each [_ e (ipairs entities)]
      (draw-entity w e.eid))))

{: draw-world : draw-entity : tile-w : tile-h : toggle-grid}
