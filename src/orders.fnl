;; aurelius.orders --- commands as data (ADR-0009).
;; Commands are the ONLY input to the simulation.

(local world (require :src.world))
(local content (require :src.content))

;; Constructors (just data)
(fn move [eid tx ty] {:tag :move :eid eid :tx tx :ty ty})
(fn gather [eid node-id] {:tag :gather :eid eid :node node-id})
(fn attack [eid tgt] {:tag :attack :eid eid :target tgt})
(fn train [prod-id tag] {:tag :train :prod prod-id :unit tag})
(fn advance-age [player] {:tag :advance-age :player player})

;; Queueing
(fn issue! [w order]
  (table.insert w.orders 1 order)
  order)

;; Aim a task at a target entity's position
(fn aim-at-target! [t w target]
  (set t.target target)
  (when target
    (let [p (world.world-get w target :position)]
      (when p
        (set t.tx p.x)
        (set t.ty p.y)))))

;; Apply a single command
(fn apply-one! [w order]
  (match order.tag
    :move
    (let [t (world.world-get w order.eid :task)]
      (when t
        (set t.kind :move)
        (set t.phase nil)
        (set t.target nil)
        (set t.tx order.tx)
        (set t.ty order.ty)
        true))

    :gather
    (let [t (world.world-get w order.eid :task)]
      (when (and t (world.world-has? w order.node :node))
        (set t.kind :gather)
        (set t.phase :to-node)
        (aim-at-target! t w order.node)
        true))

    :attack
    (let [t (world.world-get w order.eid :task)]
      (when (and t (world.world-has? w order.target :health))
        (set t.kind :attack)
        (set t.phase nil)
        (aim-at-target! t w order.target)
        true))

    :train
    (let [p (world.world-get w order.prod :producer)
          o (world.world-get w order.prod :owner)]
      (when (and p o)
        (let [tag (. (world.world-get w order.prod :kind) :tag)
              trains (content.producer-trains tag)]
          (var found false)
          (each [_ t (ipairs trains)]
            (when (= t order.unit) (set found true)))
          (when (and found (world.pay! w o.player (content.unit-cost order.unit)))
            (table.insert p.queue order.unit)
            true))))

    :advance-age
    (let [next-age (+ 1 (world.player-age w order.player))]
      (when (and (<= next-age (content.max-age))
                 (= (world.age-progress w order.player) nil)
                 (world.pay! w order.player (content.age-cost next-age)))
        (world.set-age-progress! w order.player (content.age-time next-age))
        true))

    _ false))

;; Drain and apply the whole queue oldest-first, logging each command.
(fn apply-orders! [w]
  (let [pending w.orders]
    (set w.orders [])
    (each [_ o (ipairs pending)]
      (apply-one! w o)
      (table.insert w.log 1 o))))

;; Serialization (ADR-0009)
(fn orders->log [w] w.log)
(fn log->orders [lst] lst)

{: move : gather : attack : train : advance-age
 : issue! : apply-orders! : orders->log : log->orders}
