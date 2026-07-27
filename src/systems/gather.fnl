;; aurelius.systems.gather --- villagers harvest nodes and deposit at a TC.
;; Phase machine: to-node -> gathering -> to-drop.
;; Gather RATE scales with age (ADR-0011).

(local world (require :src.world))
(local content (require :src.content))
(local movement (require :src.systems.movement))

(fn owner-of [w eid]
  (let [o (world.world-get w eid :owner)]
    (and o o.player)))

;; Nearest own Town Centre
(fn nearest-dropoff [w villager]
  (let [pl (owner-of w villager)
        (vx vy) (movement.entity-pos w villager)]
    (when (and pl vx)
      (var best nil)
      (var bd nil)
      (each [_ pair (ipairs (world.world-query w :kind))]
        (let [eid pair.eid
              tag (. pair.val :tag)
              own (world.world-get w eid :owner)]
          (when (and (= tag :town-centre) own (= own.player pl))
            (let [(px py) (movement.entity-pos w eid)
                  d (movement.cheby vx vy px py)]
              (when (or (= bd nil) (< d bd))
                (set best eid)
                (set bd d))))))
      best)))

(fn go-idle! [t]
  (set t.kind :idle)
  (set t.phase nil))

(fn aim! [w t eid]
  (let [(px py) (movement.entity-pos w eid)]
    (when px
      (set t.tx px)
      (set t.ty py))))

(fn start-drop! [w v t]
  (let [tc (nearest-dropoff w v)]
    (if tc
        (do (set t.phase :to-drop) (aim! w t tc))
        (go-idle! t))))

(fn dropoff-adjacent? [w v]
  (let [tc (nearest-dropoff w v)]
    (when tc
      (let [(px py) (movement.entity-pos w tc)]
        (when (movement.within? w v px py 1)
          tc)))))

(fn gather-system [w]
  (each [_ pair (ipairs (world.world-query w :task))]
    (let [v pair.eid t pair.val]
      (when (= t.kind :gather)
        (let [node-id t.target
              node (when node-id (world.world-get w node-id :node))
              cargo (world.world-get w v :carry)]
          (match t.phase
            :to-node
            (if
              (not node) (go-idle! t)
              (movement.within? w v t.tx t.ty 1)
              (set t.phase :gathering)
              true (movement.step-toward! w v t.tx t.ty))

            :gathering
            (if
              (not node)
              (if (> cargo.amount 0) (start-drop! w v t) (go-idle! t))
              true
              (do
                (when (not cargo.resource)
                  (set cargo.resource node.resource))
                (let [tag (. (. (. w.store :kind) v) :tag)
                      cap (content.gather-capacity tag)
                      want (math.max 1 (world.effective-gather-rate w v))
                      got (math.min want node.amount (- cap cargo.amount))]
                  (set cargo.amount (+ cargo.amount got))
                  (set node.amount (- node.amount got))
                  (when (<= node.amount 0)
                    (world.world-remove-entity! w node-id))
                  (when (>= cargo.amount cap)
                    (start-drop! w v t)))))

            :to-drop
            (let [dropoff (dropoff-adjacent? w v)]
              (if dropoff
                  (do
                    (world.add-resource! w (owner-of w v) cargo.resource cargo.amount)
                    (set cargo.amount 0)
                    (set cargo.resource nil)
                    (if node
                        (do (set t.phase :to-node) (aim! w t node-id))
                        (go-idle! t)))
                  (movement.step-toward! w v t.tx t.ty)))

            ;; default: go idle
            _ (go-idle! t)))))))

{: gather-system : nearest-dropoff}
