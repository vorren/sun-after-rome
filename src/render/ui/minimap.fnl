;; aurelius.render.ui.minimap --- mini map showing the game world.
;; Renders terrain as colored pixels, units as dots, viewport rectangle.
;; Click to scroll view, toggle with F2.

(local world (require :src.world))
(local iso (require :src.render.iso))
(local camera (require :src.render.camera))
(local log (require :src.log))

(var canvas nil)
(var visible true)
(var last-update-tick 0)
(var update-interval 10)

;; minimap dimensions
(local mm-w 180)
(local mm-h 120)

;; terrain colors
(local terrain-colors
  {:water  [0.3 0.5 0.8]
   :grass  [0.4 0.6 0.3]
   :dirt   [0.6 0.5 0.3]
   :forest [0.2 0.4 0.2]
   :stone  [0.5 0.5 0.5]})

;; faction colors
(local faction-colors
  {[0] [0.2 0.4 0.9]   ;; blue
   [1] [0.9 0.2 0.2]}) ;; red

(fn toggle []
  "Toggle minimap visibility."
  (set visible (not visible))
  (log.debug :minimap (if visible "shown" "hidden")))

(fn init []
  "Create minimap canvas."
  (set canvas (love.graphics.newCanvas mm-w mm-h))
  (log.info :minimap "Minimap initialized"))

(fn draw-terrain [terrain w]
  "Draw terrain pixels to canvas."
  (when terrain
    (let [pixel-w (/ mm-w w.width)
          pixel-h (/ mm-h w.height)]
      ;; draw terrain tiles
      (for [x 0 (- w.width 1)]
        (for [y 0 (- w.height 1)]
          (let [tile (. (. terrain x) y)
                color (or (. terrain-colors tile) [0.5 0.5 0.5])]
            (love.graphics.setColor (. color 1) (. color 2) (. color 3))
            (love.graphics.rectangle :fill
                                     (* x pixel-w) (* y pixel-h)
                                     (+ pixel-w 1) (+ pixel-h 1))))))))

(fn draw-entities [w]
  "Draw entity dots on minimap."
  (let [pixel-w (/ mm-w w.width)
        pixel-h (/ mm-h w.height)]
    (each [_ pair (ipairs (world.world-query w :position))]
      (let [eid pair.eid
            pos pair.val
            owner (world.world-get w eid :owner)
            kind (world.world-get w eid :kind)]
        (when (and owner kind)
          (let [color (or (. faction-colors owner.player) [0.5 0.5 0.5])
                px (* pos.x pixel-w)
                py (* pos.y pixel-h)]
            (love.graphics.setColor (. color 1) (. color 2) (. color 3))
            (love.graphics.rectangle :fill (- px 1) (- py 1) 3 3)))))))

(fn draw-viewport [w screen-w screen-h mm-x mm-y]
  "Draw viewport rectangle on minimap."
  (let [pixel-w (/ mm-w w.width)
        pixel-h (/ mm-h w.height)
        ;; calculate viewport in tile coordinates
        tile-w 64
        tile-h 32
        (offset-x offset-y) (camera.get-offset)
        center-x (/ screen-w 2)
        center-y (/ screen-h 2)
        (tile-cx tile-cy) (iso.to-tile (- center-x offset-x)
                                       (- center-y offset-y)
                                       tile-w tile-h)
        ;; viewport size in tiles
        view-w (/ screen-w tile-w)
        view-h (/ screen-h tile-h)]
    (love.graphics.setColor 1 1 1 0.8)
    (love.graphics.setLineWidth 1)
    (love.graphics.rectangle :line
                             (+ mm-x (* (- tile-cx (/ view-w 2)) pixel-w))
                             (+ mm-y (* (- tile-cy (/ view-h 2)) pixel-h))
                             (* view-w pixel-w)
                             (* view-h pixel-h))))

(fn update-canvas [terrain w]
  "Update minimap canvas (called every N ticks)."
  (when (and canvas visible)
    (love.graphics.setCanvas canvas)
    (love.graphics.clear 0.1 0.1 0.1)
    (draw-terrain terrain w)
    (draw-entities w)
    (love.graphics.setCanvas)))

(fn draw [terrain w]
  "Draw minimap on screen."
  (when visible
    (let [(screen-w screen-h) (love.graphics.getDimensions)
          mm-x (- screen-w mm-w 10)
          mm-y (- screen-h mm-h 10)]
      ;; update canvas periodically
      (when (>= (- w.tick last-update-tick) update-interval)
        (update-canvas terrain w)
        (set last-update-tick w.tick))
      ;; draw canvas to screen
      (love.graphics.setColor 1 1 1)
      (love.graphics.draw canvas mm-x mm-y)
      ;; draw viewport rectangle
      (draw-viewport w screen-w screen-h mm-x mm-y)
      ;; draw border
      (love.graphics.setColor 0.96 0.90 0.78)
      (love.graphics.setLineWidth 2)
      (love.graphics.rectangle :line mm-x mm-y mm-w mm-h))))

(fn handle-click [x y w screen-w screen-h]
  "Handle click on minimap — scroll view to clicked position."
  (when visible
    (let [mm-x (- screen-w mm-w 10)
          mm-y (- screen-h mm-h 10)
          rel-x (- x mm-x)
          rel-y (- y mm-y)]
      (when (and (>= rel-x 0) (<= rel-x mm-w)
                 (>= rel-y 0) (<= rel-y mm-h))
        ;; convert minimap coords to tile coords
        (let [tile-x (* (/ rel-x mm-w) w.width)
              tile-y (* (/ rel-y mm-h) w.height)]
          (log.debug :minimap (.. "Scrolling to tile " tile-x "," tile-y))
          ;; scroll camera to this tile
          (camera.scroll-to-tile tile-x tile-y 64 32 screen-w screen-h)
          true)))))

{: init : draw : toggle : handle-click}
