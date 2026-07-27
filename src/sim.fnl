;; aurelius.sim --- the fixed-timestep tick loop (ADR-0005).
;; System order is fixed and explicit; that order + seed + command log fully determine the run.

(local world (require :src.world))
(local orders (require :src.orders))
(local production (require :src.systems.production))
(local age (require :src.systems.age))
(local movement (require :src.systems.movement))
(local gather (require :src.systems.gather))
(local combat (require :src.systems.combat))
(local ai (require :src.ai.scripted))

;; Controller dispatch (ADR-0015/0016): runs after apply-orders!, calls each
;; faction's controller tick. AI controllers issue orders that apply next tick.
(fn controller-dispatch! [w]
  (for [p 0 (- w.num-players 1)]
    (let [ctrl (world.get-controller w p)]
      (when (and ctrl ctrl.tick)
        (ctrl.tick w)))))

;; AI takeover (ADR-0016): replace disconnected player's controller with deterministic AI.
(fn take-player! [w p]
  "Replace player P's controller with an AI takeover controller."
  (world.set-controller! w p (ai.make-ai-takeover p)))

;; The ordered pipeline
(var systems [])

(fn init-systems! []
  (set systems [orders.apply-orders!
                controller-dispatch!
                production.production-system
                age.age-system
                movement.movement-system
                gather.gather-system
                combat.combat-system]))

(fn tick! [w]
  (each [_ sys (ipairs systems)]
    (sys w))
  (set w.tick (+ 1 w.tick))
  w)

(fn run! [w n]
  (for [_ 1 n]
    (tick! w))
  w)

(fn reset-systems! []
  (init-systems!))

;; Initialize on load
(init-systems!)

{: tick! : run! : systems : reset-systems! : take-player!}
