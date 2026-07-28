;; aurelius.world --- the world value: entity/component store, per-player resources,
;; ages, RNG, and snapshot/restore.
;; ADR-0003/0004/0005/0006.

(local components (require :src.components))
(local content (require :src.content))
(local rng (require :src.rng))

(local component-types
  [:position :owner :kind :health :carry :node :cooldown :producer :task :task-queue])

(fn make-world [{: width : height : players : seed}]
  (let [store {}]
    (each [_ ct (ipairs component-types)]
      (tset store ct {}))
    {:tick 0
     :width (or width 24)
     :height (or height 16)
     :num-players (or players 2)
     :store store
     :resources (let [r {}] (for [p 1 (or players 2)] (tset r p {})) r)
     :ages (let [a {}] (for [p 1 (or players 2)] (tset a p 1)) a)
     :age-progress (let [ap {}] (for [p 1 (or players 2)] (tset ap p nil)) ap)
     :rng (rng.make-rng (or seed 1))
     :orders []
     :log []
     :next-id 1
     :controllers (let [c {}] (for [p 1 (or players 2)] (tset c p {:type :idle})) c)}))

;; Entity + component store
(fn fresh-id! [w]
  (let [id w.next-id]
    (set w.next-id (+ id 1))
    id))

(fn ctype-table [w ct]
  (or (. w.store ct) (error (.. "unknown component type: " (tostring ct)))))

(fn world-add! [w eid ct value]
  (tset (ctype-table w ct) eid value)
  value)

(fn world-get [w eid ct]
  (. (ctype-table w ct) eid))

(fn world-has? [w eid ct]
  (not= (. (ctype-table w ct) eid) nil))

(fn world-remove-component! [w eid ct]
  (tset (ctype-table w ct) eid nil))

;; All entities holding component CT, sorted by eid (determinism).
(fn world-query [w ct]
  (let [t (ctype-table w ct)
        result []]
    (each [eid val (pairs t)]
      (table.insert result {:eid eid :val val}))
    (table.sort result (fn [a b] (< a.eid b.eid)))
    result))

;; All live entity ids (anything with a kind), sorted.
(fn world-entities [w]
  (let [result []]
    (each [_ pair (ipairs (world-query w :kind))]
      (table.insert result pair.eid))
    result))

(fn world-remove-entity! [w eid]
  (each [_ ct (ipairs component-types)]
    (tset (ctype-table w ct) eid nil)))

;; Controllers (ADR-0015)
(fn set-controller! [w p ctrl]
  (tset w.controllers (+ p 1) ctrl))

(fn get-controller [w p]
  (. w.controllers (+ p 1)))

;; Ages (ADR-0011) - defined early so effective-* can use them
;; Player indices are 0-based in game logic, 1-based in Lua tables
(fn player-age [w p] (. w.ages (+ p 1)))
(fn set-player-age! [w p level] (tset w.ages (+ p 1) level))
(fn age-progress [w p] (. w.age-progress (+ p 1)))
(fn set-age-progress! [w p v] (tset w.age-progress (+ p 1) v))

;; Effective (age-adjusted) stats (ADR-0011) - must come before spawn!
(fn owner-of [w eid]
  (let [o (world-get w eid :owner)]
    (and o o.player)))

(fn mult [w eid key]
  (let [p (owner-of w eid)]
    (if (and p (>= p 0)) (content.age-bonus (player-age w p) key) 1)))

(fn effective-max-hp [w eid]
  (let [tag (. (. (. w.store :kind) eid) :tag)]
    (math.floor (* (content.base-max-hp tag) (mult w eid :hp)))))

(fn effective-gather-rate [w eid]
  (let [tag (. (. (. w.store :kind) eid) :tag)]
    (math.floor (* (content.kind-stat tag :gather-rate 0) (mult w eid :gather)))))

(fn effective-damage [w eid base]
  (math.floor (* base (mult w eid :damage))))

;; Spawning: build an entity's components from its content kind.
(fn spawn! [w tag opts]
  (let [id (fresh-id! w)
        opts (or opts {})]
    (world-add! w id :kind (components.make-kind tag))
    (world-add! w id :position (components.make-position (or opts.x 0) (or opts.y 0)))
    (when opts.owner
      (world-add! w id :owner (components.make-owner opts.owner)))
    ;; health for anything with hit points
    (let [hp (content.kind-stat tag :max-hp)]
      (when hp
        (world-add! w id :health (components.make-health (content.base-max-hp tag)))
        (let [h (world-get w id :health)]
          (set h.hp (effective-max-hp w id)))))
    ;; resource node
    (let [res (content.kind-stat tag :node)]
      (when res
        (world-add! w id :node (components.make-node res (content.kind-stat tag :amount 0)))))
    ;; production building
    (when (> (# (content.producer-trains tag)) 0)
      (world-add! w id :producer (components.make-producer [] 0)))
    ;; villager cargo
    (when (= tag :villager)
      (world-add! w id :carry (components.make-carry nil 0)))
    ;; military attack cooldown + idle task
    (when (> (content.kind-stat tag :damage 0) 0)
      (world-add! w id :cooldown (components.make-cooldown 0)))
    (when (or (= tag :villager) (> (content.kind-stat tag :damage 0) 0))
      (world-add! w id :task (components.make-task :idle nil nil nil nil))
      (world-add! w id :task-queue (components.make-task-queue)))
    id))

;; Resources (ADR-0008)
(fn resource-amount [w p res]
  (or (. (. w.resources (+ p 1)) res) 0))

(fn add-resource! [w p res n]
  (let [current (resource-amount w p res)]
    (tset (. w.resources (+ p 1)) res (+ current n))))

(fn can-afford? [w p cost]
  (var ok true)
  (each [res amount (pairs cost)]
    (when (< (resource-amount w p res) amount)
      (set ok false)))
  ok)

(fn pay! [w p cost]
  (when (can-afford? w p cost)
    (each [res amount (pairs cost)]
      (add-resource! w p res (- amount)))
    true))

;; Snapshot / restore (ADR-0004): deep independent copy.
(fn copy-table [t]
  (let [out {}]
    (each [k v (pairs t)]
      (tset out k (if (= (type v) :table) (copy-table v) v)))
    out))

(fn copy-component [ct v]
  (match ct
    :position (components.make-position v.x v.y)
    :owner (components.make-owner v.player)
    :kind (components.make-kind v.tag)
    :health (components.make-health v.hp)
    :carry (components.make-carry v.resource v.amount)
    :node (components.make-node v.resource v.amount)
    :cooldown (components.make-cooldown v.ticks)
    :producer (components.make-producer (copy-table v.queue) v.progress)
    :task (components.make-task v.kind v.target v.tx v.ty v.phase)
    _ (copy-table v)))

(fn snapshot [w]
  (let [store {}]
    (each [_ ct (ipairs component-types)]
      (let [src (. w.store ct)
            dst {}]
        (each [eid v (pairs src)]
          (tset dst eid (copy-component ct v)))
        (tset store ct dst)))
    {:tick w.tick
     :width w.width
     :height w.height
     :num-players w.num-players
     :store store
     :resources (copy-table w.resources)
     :ages (copy-table w.ages)
     :age-progress (copy-table w.age-progress)
     :rng (rng.make-rng (rng.rng-state w.rng))
     :orders (copy-table w.orders)
     :log (copy-table w.log)
     :next-id w.next-id
     :controllers (copy-table w.controllers)}))

{: make-world : fresh-id!
 : world-add! : world-get : world-has? : world-remove-component!
 : world-query : world-remove-entity! : world-entities
 : spawn!
 : set-controller! : get-controller
 : player-age : set-player-age! : age-progress : set-age-progress!
 : effective-max-hp : effective-gather-rate : effective-damage
 : owner-of : resource-amount : add-resource! : can-afford? : pay!
 : snapshot : component-types}
