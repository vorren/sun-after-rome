;; aurelius.sim --- the fixed-timestep tick loop (ADR-0005).
;; System order is fixed and explicit; that order + seed + command log fully determine the run.

(local world (require :src.world))
(local orders (require :src.orders))
(local production (require :src.systems.production))
(local age (require :src.systems.age))
(local movement (require :src.systems.movement))
(local gather (require :src.systems.gather))
(local combat (require :src.systems.combat))

;; The ordered pipeline
(var systems [])

(fn init-systems! []
  (set systems [orders.apply-orders!
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

{: tick! : run! : systems : reset-systems!}
