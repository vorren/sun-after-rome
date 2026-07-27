;; aurelius.systems.movement --- grid geometry + straight-line stepping.
;; ADR-0012: units walk straight toward destination, no obstacle avoidance.

(local world (require :src.world))
(local content (require :src.content))

(fn sgn [n]
  (if (> n 0) 1 (< n 0) -1 0))

(fn cheby [x1 y1 x2 y2]
  (math.max (math.abs (- x1 x2)) (math.abs (- y1 y2))))

(fn entity-pos [w eid]
  (let [p (world.world-get w eid :position)]
    (when p (values p.x p.y))))

(fn speed-of [w eid]
  (let [tag (. (. (. w.store :kind) eid) :tag)]
    (content.kind-stat tag :speed 1)))

;; Move eid up to its speed in single tiles toward (tx,ty).
(fn step-toward! [w eid tx ty]
  (let [p (world.world-get w eid :position)
        steps (speed-of w eid)]
    (for [_ 1 steps]
      (let [x p.x y p.y]
        (when (not (and (= x tx) (= y ty)))
          (set p.x (math.max 0 (math.min (- w.width 1) (+ x (sgn (- tx x))))))
          (set p.y (math.max 0 (math.min (- w.height 1) (+ y (sgn (- ty y)))))))))))

(fn at-tile? [w eid tx ty]
  (let [p (world.world-get w eid :position)]
    (and (= p.x tx) (= p.y ty))))

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

{: sgn : cheby : entity-pos : speed-of : step-toward! : at-tile? : within? : movement-system}
