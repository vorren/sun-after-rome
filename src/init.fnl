;; aurelius.init --- LÖVE callbacks: love.load, love.update, love.draw, etc.
;; This is the main game module.

(local world (require :src.world))
(local sim (require :src.sim))
(local orders (require :src.orders))
(local movement (require :src.systems.movement))
(local sprites (require :src.render.sprites))
(local hud (require :src.render.hud))
(local map (require :src.render.map))
(local lockstep (require :src.net.lockstep))

(var game-world nil)
(var terrain nil)

(fn love.load []
  ;; Create the game world
  (set game-world (world.make-world {:width 24 :height 16 :players 2 :seed 42}))
  ;; Spawn initial entities
  (world.spawn! game-world :town-centre {:owner 0 :x 3 :y 3})
  (world.spawn! game-world :town-centre {:owner 1 :x 20 :y 12})
  (world.spawn! game-world :barracks {:owner 0 :x 5 :y 3})
  (world.spawn! game-world :barracks {:owner 1 :x 18 :y 12})
  ;; Villagers
  (world.spawn! game-world :villager {:owner 0 :x 4 :y 4})
  (world.spawn! game-world :villager {:owner 0 :x 4 :y 5})
  (world.spawn! game-world :villager {:owner 1 :x 19 :y 11})
  ;; Resource nodes
  (world.spawn! game-world :tree {:x 8 :y 6})
  (world.spawn! game-world :tree {:x 9 :y 6})
  (world.spawn! game-world :tree {:x 8 :y 7})
  (world.spawn! game-world :gold-mine {:x 12 :y 8})
  (world.spawn! game-world :stone-mine {:x 15 :y 10})
  ;; Generate terrain
  (set terrain (map.init-map game-world 42))
  ;; Start REPL thread
  (let [(ok repl) (pcall require "lib.stdio")]
    (when ok
      (repl.start)))
  ;; Set love.update ticks
  (print "Sun After Rome loaded. Press F5 to reset, click to select."))

(var accumulator 0)
(var tick-dt (/ 1 15))  ;; 15 Hz tick rate

(fn love.update [raw-dt]
  ;; Clamp large dt (e.g. on resume)
  (var dt raw-dt)
  (when (> dt 0.1)
    (set dt 0.1))
  ;; Accumulate time and tick when ready
  (set accumulator (+ accumulator dt))
  (while (>= accumulator tick-dt)
    (set accumulator (- accumulator tick-dt))
    ;; Tick simulation
    (sim.tick! game-world)))

(fn love.draw []
  ;; Draw terrain
  (when terrain
    (map.draw-terrain terrain game-world))
  ;; Draw entities
  (sprites.draw-world game-world)
  ;; Draw HUD
  (hud.draw-hud game-world))

(fn love.keypressed [key]
  (match key
    :f5 (do
          ;; Reset world
          (set game-world (world.make-world {:width 24 :height 16 :players 2 :seed 42}))
          (world.spawn! game-world :town-centre {:owner 0 :x 3 :y 3})
          (world.spawn! game-world :town-centre {:owner 1 :x 20 :y 12})
          (world.spawn! game-world :barracks {:owner 0 :x 5 :y 3})
          (world.spawn! game-world :barracks {:owner 1 :x 18 :y 12})
          (world.spawn! game-world :villager {:owner 0 :x 4 :y 4})
          (world.spawn! game-world :villager {:owner 0 :x 4 :y 5})
          (world.spawn! game-world :villager {:owner 1 :x 19 :y 11})
          (world.spawn! game-world :tree {:x 8 :y 6})
          (world.spawn! game-world :tree {:x 9 :y 6})
          (world.spawn! game-world :tree {:x 8 :y 7})
          (world.spawn! game-world :gold-mine {:x 12 :y 8})
          (world.spawn! game-world :stone-mine {:x 15 :y 10})
          (set terrain (map.init-map game-world 42))
          (print "World reset."))
    :escape (love.event.quit)
    ;; Quick commands
    :1 (orders.issue! game-world (orders.train 2 :villager))
    :2 (orders.issue! game-world (orders.train 3 :knight))
    :3 (orders.issue! game-world (orders.train 3 :pikeman))
    :4 (orders.issue! game-world (orders.train 3 :archer))
    :a (orders.issue! game-world (orders.advance-age 0))
    :b (orders.issue! game-world (orders.advance-age 1))))

(fn love.mousepressed [x y button]
  (when (= button 1)
    (hud.handle-click x y game-world)))

;; Expose game-world for REPL access
(fn get-world [] game-world)
(fn get-terrain [] terrain)

{: get-world : get-terrain}
