;; aurelius.net.lockstep --- deterministic lockstep simulation coordinator.
;; Both players run the full simulation; exchange commands each tick.

(local world (require :src.world))
(local orders (require :src.orders))
(local sim (require :src.sim))

(var tick-rate 15)  ;; Hz, matching AoE2's pace
(var pending-commands [])
(var remote-commands [])
(var connected false)
(var is-host false)

(fn set-tick-rate! [hz]
  (set tick-rate hz))

(fn add-local-command! [cmd]
  (table.insert pending-commands cmd))

(fn receive-remote-commands! [cmds]
  (set remote-commands cmds))

;; Called each love.update; returns true if tick advanced
(fn maybe-tick [w dt]
  (let [tick-duration (/ 1 tick-rate)]
    ;; Accumulate time and tick when ready
    (when (not w._net-timer)
      (set w._net-timer 0))
    (set w._net-timer (+ w._net-timer dt))
    (when (>= w._net-timer tick-duration)
      (set w._net-timer (- w._net-timer tick-duration))
      ;; Apply local commands
      (each [_ cmd (ipairs pending-commands)]
        (orders.issue! w cmd))
      (set pending-commands [])
      ;; Apply remote commands
      (each [_ cmd (ipairs remote-commands)]
        (orders.issue! w cmd))
      (set remote-commands [])
      ;; Advance simulation
      (sim.tick! w)
      true)))

(fn get-pending-commands []
  pending-commands)

(fn reset-net! []
  (set pending-commands [])
  (set remote-commands [])
  (set connected false))

{: set-tick-rate! : add-local-command! : receive-remote-commands!
 : maybe-tick : get-pending-commands : reset-net!}
