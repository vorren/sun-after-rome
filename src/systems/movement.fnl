;; aurelius.systems.movement --- smooth movement with push collision.
;; ADR-0012: units walk toward destination with collision response.

(local world (require :src.world))
(local content (require :src.content))

(fn cheby [x1 y1 x2 y2]
  (math.max (math.abs (- x1 x2)) (math.abs (- y1 y2))))

(fn entity-pos [w eid]
  (let [p (world.world-get w eid :position)]
    (when p (values p.x p.y))))

(fn speed-of [w eid]
  (let [tag (. (. (. w.store :kind) eid) :tag)]
    (content.kind-stat tag :speed 1)))

(fn collision-radius [w eid]
  (let [tag (. (. (. w.store :kind) eid) :tag)]
    (or (content.kind-stat tag :collision-radius 0) 0)))

(fn entity-at-tile [w x y exclude-eid]
  (var best nil)
  (var best-dist nil)
  (each [_ pair (ipairs (world.world-query w :position))]
    (let [eid pair.eid
          pos pair.val]
      (when (not= eid exclude-eid)
        (let [d (cheby pos.x pos.y x y)]
          (when (or (= best-dist nil) (< d best-dist))
            (set best eid)
            (set best-dist d))))))
  best)

(fn blocks-movement? [w eid]
  "Check if entity blocks movement (has :blocks true in content)."
  (let [kind (world.world-get w eid :kind)]
    (when kind
      (content.kind-stat kind.tag :blocks false))))

(fn would-collide [w eid tx ty]
  (let [other (entity-at-tile w tx ty eid)]
    (when other
      ;; buildings with :blocks true always block
      (if (blocks-movement? w other)
          true
          ;; units collide based on collision radius
          (let [cr (collision-radius w eid)
                or2 (collision-radius w other)]
            (< (+ cr or2) 1.0))))))

(fn push-entity [w eid tx ty]
  (let [other (entity-at-tile w tx ty eid)]
    (when other
      (let [op (world.world-get w other :position)
            ep (world.world-get w eid :position)]
        (when (and op ep)
          (var dx (- ep.x op.x))
          (var dy (- ep.y op.y))
          (when (and (= dx 0) (= dy 0))
            (set dx 1))
          (let [dist (math.sqrt (+ (* dx dx) (* dy dy)))
                nx (/ dx dist)
                ny (/ dy dist)
                cr (collision-radius w eid)
                or2 (collision-radius w other)
                push-dist (* 0.3 (+ cr or2))
                push-x (+ op.x (* nx push-dist))
                push-y (+ op.y (* ny push-dist))]
            (set op.x (math.max 0 (math.min (- w.width 1) push-x)))
            (set op.y (math.max 0 (math.min (- w.height 1) push-y)))))))))

(fn step-toward! [w eid tx ty]
  (let [p (world.world-get w eid :position)
        spd (speed-of w eid)
        dx (- tx p.x)
        dy (- ty p.y)
        dist (math.sqrt (+ (* dx dx) (* dy dy)))]
    (when (> dist 0.01)
      (let [step (math.min spd dist)
            nx (/ dx dist)
            ny (/ dy dist)
            new-x (+ p.x (* nx step))
            new-y (+ p.y (* ny step))
            clamp-x (math.max 0 (math.min (- w.width 1) new-x))
            clamp-y (math.max 0 (math.min (- w.height 1) new-y))]
        (when (would-collide w eid clamp-x clamp-y)
          (push-entity w eid clamp-x clamp-y))
        (set p.x clamp-x)
        (set p.y clamp-y)))))

(fn at-tile? [w eid tx ty]
  (let [p (world.world-get w eid :position)]
    (<= (cheby p.x p.y tx ty) 0.5)))

(fn within? [w eid tx ty dist]
  (let [p (world.world-get w eid :position)]
    (<= (cheby p.x p.y tx ty) dist)))

(fn movement-system [w]
  (each [_ pair (ipairs (world.world-query w :task))]
    (let [eid pair.eid t pair.val]
      (when (= t.kind :move)
        (if (at-tile? w eid t.tx t.ty)
            (set t.kind :idle)
            (step-toward! w eid t.tx t.ty))))))

{: cheby : entity-pos : speed-of : collision-radius : entity-at-tile
 : would-collide : push-entity : step-toward! : at-tile? : within? : movement-system}
