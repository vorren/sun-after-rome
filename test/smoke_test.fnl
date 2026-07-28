;; test/smoke_test.fnl --- smoke test that loads the game and checks for errors.
;; Run with: love . --smoke-test
;; Exits with code 0 on success, 1 on failure.

(local world (require :src.world))
(local sim (require :src.sim))

(var error-msg nil)

(fn love.load []
  (let [(ok err) (pcall
                   (fn []
                     (let [hud (require :src.render.hud)
                           sprites (require :src.render.sprites)
                           floating-text (require :src.render.floating-text)]
                       ;; Test cursor initialization
                       (hud.init-cursors)
                       ;; Test basic world creation
                       (let [w (world.make-world {:width 24 :height 16 :players 2 :seed 42})]
                         (world.spawn! w :town-centre {:owner 0 :x 3 :y 3})
                         (world.spawn! w :villager {:owner 0 :x 4 :y 4})
                         ;; Test a tick
                         (sim.tick! w)
                         ;; Test HUD draw
                         (hud.draw-hud w)
                         ;; Test selection highlight
                         (hud.draw-selection-highlight w)
                         ;; Test floating text
                         (floating-text.draw-texts w)
                         true))))]
    (when (not ok)
      (set error-msg err)
      (print (.. "SMOKE TEST FAILED: " err))
      ;; Print stack trace for debugging
      (when (and err (not= err ""))
        (print "Stack trace:")
        (print err)))
    ;; Quit immediately
    (love.event.quit (if error-msg 1 0))))

(fn love.update [dt]
  nil)

(fn love.draw []
  nil)
