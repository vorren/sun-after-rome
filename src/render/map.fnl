;; aurelius.render.map --- Tiled map loading + procedural generation.

(local world (require :src.world))

(var current-map nil)
(var use-procedural true)

;; Procedural map generation using LÖVE's built-in Perlin noise
(fn generate-procedural [w seed]
  (let [terrain {}]
    (math.randomseed (or seed 42))
    (for [x 0 (- w.width 1)]
      (tset terrain x {})
      (for [y 0 (- w.height 1)]
        (let [n (love.math.noise (* x 0.1) (* y 0.1) 0.5)
              tile (if (< n 0.3) :water
                       (< n 0.5) :grass
                       (< n 0.7) :dirt
                       (< n 0.85) :forest
                       :stone)]
          (tset (. terrain x) y tile))))
    terrain))

(fn draw-terrain [terrain w]
  (when terrain
    (let [iso (require :src.render.iso)]
      (for [x 0 (- w.width 1)]
        (for [y 0 (- w.height 1)]
          (let [tile (. (. terrain x) y)
                (raw-sx raw-sy) (iso.to-screen x y 64 32)]
            ;; Offset to center
            (var sx (+ raw-sx 640))
            (var sy (+ raw-sy 100))
            (match tile
              :water  (love.graphics.setColor 0.2 0.4 0.8)
              :grass  (love.graphics.setColor 0.3 0.6 0.2)
              :dirt   (love.graphics.setColor 0.6 0.5 0.3)
              :forest (love.graphics.setColor 0.1 0.4 0.1)
              :stone  (love.graphics.setColor 0.5 0.5 0.5)
              _       (love.graphics.setColor 0.3 0.3 0.3))
            ;; Draw filled diamond
            (love.graphics.polygon :fill
                                   sx (- sy 16)
                                   (+ sx 32) sy
                                   sx (+ sy 16)
                                   (- sx 32) sy)))))))

(fn init-map [w seed]
  (when use-procedural
    (generate-procedural w seed)))

{: generate-procedural : draw-terrain : init-map}
