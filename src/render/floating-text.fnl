;; aurelius.render.floating-text --- floating text feedback for commands.

(local world (require :src.world))
(local iso (require :src.render.iso))

(var texts [])

(fn add-text [w eid label]
  (let [pos (world.world-get w eid :position)]
    (when pos
      (table.insert texts {:eid eid
                           :label label
                           :lifetime 1.0
                           :x pos.x
                           :y pos.y}))))

(fn update-texts [dt]
  (var i 1)
  (while (<= i (# texts))
    (let [t (. texts i)]
      (set t.lifetime (- t.lifetime dt))
      (when (<= t.lifetime 0)
        (table.remove texts i))
      (when (> t.lifetime 0)
        (set i (+ i 1))))))

(fn draw-texts [w]
  (each [_ t (ipairs texts)]
    (let [pos (world.world-get w t.eid :position)]
      (when pos
        (let [tile-w 64
              tile-h 32
              offset-x 640
              offset-y 100
              (sx sy) (iso.to-screen pos.x pos.y tile-w tile-h)
              screen-x (+ sx offset-x)
              screen-y (+ sy offset-y)
              alpha (math.min 1.0 t.lifetime)]
          (love.graphics.setColor 1 1 1 alpha)
          (love.graphics.printf t.label (- screen-x 30) (- screen-y 30) 60 "center"))))))

(fn clear-texts []
  (set texts []))

{: add-text : update-texts : draw-texts : clear-texts}
