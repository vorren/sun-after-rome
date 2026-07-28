;; aurelius.init --- LÖVE callbacks: love.load, love.update, love.draw, etc.
;; This is the main game module.

(local world (require :src.world))
(local sim (require :src.sim))
(local orders (require :src.orders))
(local sprites (require :src.render.sprites))
(local hud (require :src.render.hud))
(local map (require :src.render.map))
(local floating-text (require :src.render.floating-text))
(local ai (require :src.ai.scripted))

(var game-world nil)
(var terrain nil)
(var music nil)

(fn spawn-initial-entities [w]
  (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
  (world.spawn! w :town-centre {:owner 1 :x 20 :y 12})
  (world.spawn! w :barracks {:owner 0 :x 5 :y 3})
  (world.spawn! w :barracks {:owner 1 :x 18 :y 12})
  (world.spawn! w :villager {:owner 0 :x 4 :y 4})
  (world.spawn! w :villager {:owner 0 :x 4 :y 5})
  (world.spawn! w :villager {:owner 1 :x 19 :y 11})
  (world.spawn! w :tree {:x 8 :y 6})
  (world.spawn! w :tree {:x 9 :y 6})
  (world.spawn! w :tree {:x 8 :y 7})
  (world.spawn! w :gold-mine {:x 12 :y 8})
  (world.spawn! w :stone-mine {:x 15 :y 10}))

(fn setup-world []
  (set game-world (world.make-world {:width 24 :height 16 :players 2 :seed 42}))
  (spawn-initial-entities game-world)
  (world.set-controller! game-world 1 (ai.make-ai-controller 1))
  (set terrain (map.init-map game-world 42))
  (floating-text.clear-texts))

(fn love.load []
  (setup-world)
  (hud.init-cursors)
  (let [(ok source) (pcall love.audio.newSource "assets/music/sar.ogg" "stream")]
    (when ok
      (set music source)
      (music:setLooping true)
      (music:setVolume 0.3)
      (love.audio.play music)))
  (let [(ok repl) (pcall require "lib.stdio")]
    (when ok
      (repl.init-env! game-world)
      (repl.start)))
  (print "Sun After Rome loaded. Press F5 to reset, click to select."))

(var accumulator 0)
(var tick-dt (/ 1 15))

(fn love.update [raw-dt]
  (var dt raw-dt)
  (when (> dt 0.1)
    (set dt 0.1))
  (set accumulator (+ accumulator dt))
  (while (>= accumulator tick-dt)
    (set accumulator (- accumulator tick-dt))
    (sim.tick! game-world))
  (floating-text.update-texts dt)
  (let [(ok repl) (pcall require "lib.stdio")]
    (when ok (repl.poll))))

(fn love.draw []
  (when terrain
    (map.draw-terrain terrain game-world))
  (sprites.draw-world game-world)
  (hud.draw-selection-highlight game-world)
  (hud.draw-drag-rect)
  (floating-text.draw-texts game-world)
  (hud.draw-hud game-world))

(fn love.keypressed [key]
  (match key
    :f5 (do
          (setup-world)
          (hud.init-cursors)
          (let [(ok repl) (pcall require "lib.stdio")]
            (when ok (repl.init-env! game-world)))
          (print "World reset."))
    :escape (do
              (hud.set-command-mode nil)
              (love.event.quit))
    :m (hud.set-command-mode :move)
    :g (hud.set-command-mode :gather)
    :a (hud.set-command-mode :attack)
    :1 (orders.issue! game-world (orders.train 2 :villager))
    :2 (orders.issue! game-world (orders.train 3 :knight))
    :3 (orders.issue! game-world (orders.train 3 :pikeman))
    :4 (orders.issue! game-world (orders.train 3 :archer))
    :space (orders.issue! game-world (orders.advance-age 0))
    :b (orders.issue! game-world (orders.advance-age 1))))

(fn love.mousepressed [x y button shift]
  (hud.handle-click x y game-world button shift)
  (when (and (= button 1) (not (hud.get-command-mode)))
    (hud.set-drag-start x y)))

(fn love.mousereleased [x y button]
  (when (and (= button 1) (hud.get-drag-start))
    (let [ds (hud.get-drag-start)]
      (when (or (not= x ds.x) (not= y ds.y))
        (let [entities (hud.entities-in-rect game-world ds.x ds.y x y)]
          (when (> (# entities) 0)
            (hud.clear-drag-start)
            (each [_ eid (ipairs entities)]
              (hud.add-to-selection eid))))))
    (hud.clear-drag-start)))

(fn love.mousemoved [x y]
  (hud.handle-mouse-move x y game-world))

(fn love.focus [focused]
  (when music
    (if focused
        (music:play)
        (love.audio.pause music))))

(fn get-world [] game-world)
(fn get-terrain [] terrain)

{: get-world : get-terrain}
