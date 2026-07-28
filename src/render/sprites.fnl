;; aurelius.render.sprites --- placeholder sprite rendering (colored shapes).
;; No asset files needed yet; units are circles, buildings are rectangles.
;; Supports float positions for smooth movement.

(local world (require :src.world))
(local iso (require :src.render.iso))

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

(fn get-color [tag]
  (or (. unit-colors tag)
      (. building-colors tag)
      (. node-colors tag)
      [0.5 0.5 0.5]))

(fn draw-entity [w eid]
  (let [kind (world.world-get w eid :kind)
        pos (world.world-get w eid :position)]
    (when (and kind pos)
      (let [tag kind.tag
            (raw-sx raw-sy) (iso.to-screen pos.x pos.y tile-w tile-h)
            color (. (get-color tag) 1)
            color2 (. (get-color tag) 2)
            color3 (. (get-color tag) 3)
            sx (+ raw-sx 640)
            sy (+ raw-sy 100)]
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
              (love.graphics.circle :line sx (- sy 8) 8)))))))

(fn draw-isometric-grid [w]
  (love.graphics.setColor 0.3 0.3 0.3 0.3)
  (for [x 0 (- w.width 1)]
    (for [y 0 (- w.height 1)]
      (let [(raw-sx raw-sy) (iso.to-screen x y tile-w tile-h)]
        (var sx (+ raw-sx 640))
        (var sy (+ raw-sy 100))
        (love.graphics.line
         sx (- sy (/ tile-h 2))
         (+ sx (/ tile-w 2)) sy
         sx (+ sy (/ tile-h 2))
         (- sx (/ tile-w 2)) sy
         sx (- sy (/ tile-h 2)))))))

(fn draw-world [w]
  (draw-isometric-grid w)
  (let [entities []]
    (each [_ pair (ipairs (world.world-query w :kind))]
      (let [eid pair.eid
            pos (world.world-get w eid :position)]
        (when pos
          (table.insert entities {:eid eid
                                  :depth (iso.depth-key pos.x pos.y)}))))
    (table.sort entities (fn [a b] (< a.depth b.depth)))
    (each [_ e (ipairs entities)]
      (draw-entity w e.eid))))

{: draw-world : draw-entity : tile-w : tile-h}
