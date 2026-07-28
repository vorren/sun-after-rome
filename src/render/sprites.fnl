;; aurelius.render.sprites --- placeholder sprite rendering with interpolation.
;; Supports smooth movement via frame interpolation and health bars.

(local world (require :src.world))
(local iso (require :src.render.iso))
(local interpolation (require :src.render.interpolation))
(local camera (require :src.render.camera))

(local tile-w 64)
(local tile-h 32)

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

(fn draw-rally-point [w eid]
  "Draw rally point flag for buildings."
  (let [producer (world.world-get w eid :producer)
        pos (world.world-get w eid :position)]
    (when (and producer producer.rally-x producer.rally-y pos)
      (let [(offset-x offset-y) (camera.get-offset)
            (raw-sx raw-sy) (iso.to-screen producer.rally-x producer.rally-y tile-w tile-h)
            sx (+ raw-sx offset-x)
            sy (+ raw-sy offset-y)]
        ;; flag pole
        (love.graphics.setColor 0.8 0.8 0.8)
        (love.graphics.setLineWidth 2)
        (love.graphics.line sx sy (- sy 20))
        ;; flag
        (love.graphics.setColor 0.9 0.2 0.2)
        (love.graphics.rectangle :fill sx (- sy 20) 10 8)
        (love.graphics.setLineWidth 1)))))

(fn draw-entity [w eid]
  (let [kind (world.world-get w eid :kind)
        pos (interpolation.interpolated-pos w eid)]
    (when (and kind pos)
      (let [tag kind.tag
            (raw-sx raw-sy) (iso.to-screen pos.x pos.y tile-w tile-h)
            (offset-x offset-y) (camera.get-offset)
            color (. (get-color tag) 1)
            color2 (. (get-color tag) 2)
            color3 (. (get-color tag) 3)
            sx (+ raw-sx offset-x)
            sy (+ raw-sy offset-y)]
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
              (love.graphics.circle :line sx (- sy 8) 8)))
        ;; draw health bar above entity
        (draw-health-bar w eid sx sy)
        ;; draw idle indicator
        (draw-idle-indicator w eid sx sy)
        ;; draw rally point for buildings
        (when (. building-colors tag)
          (draw-rally-point w eid))))))

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
