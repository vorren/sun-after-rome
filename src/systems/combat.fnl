;; aurelius.systems.combat --- melee & ranged fighting with AOE2-style
;; armour-class bonus damage (ADR-0010).

(local world (require :src.world))
(local content (require :src.content))
(local rng (require :src.rng))
(local movement (require :src.systems.movement))

(fn armour-class-of [w eid]
  (let [tag (. (. (. w.store :kind) eid) :tag)]
    (content.kind-stat tag :armour :none)))

;; Deterministic damage roll
(fn attack-damage [w attacker target]
  (let [tag (. (. (. w.store :kind) attacker) :tag)
        prof (content.attack-of tag)
        tcls (armour-class-of w target)
        bonus (or (. prof.bonus-vs tcls) 0)
        raw (world.effective-damage w attacker (+ prof.damage bonus))
        factor (rng.rng-range! w.rng 95 105)]
    (math.max 1 (math.floor (/ (* raw factor) 100)))))

(fn dead? [w eid]
  (not (world.world-has? w eid :health)))

(fn strike! [w a tgt]
  (let [h (world.world-get w tgt :health)
        hp (- h.hp (attack-damage w a tgt))]
    (if (<= hp 0)
        (world.world-remove-entity! w tgt)
        (set h.hp hp))))

(fn combat-system [w]
  ;; 1. cool everyone down
  (each [_ pair (ipairs (world.world-query w :cooldown))]
    (let [c pair.val]
      (when (> c.ticks 0)
        (set c.ticks (- c.ticks 1)))))
  ;; 2. resolve attack tasks
  (each [_ pair (ipairs (world.world-query w :task))]
    (let [a pair.eid t pair.val]
      (when (and (= t.kind :attack) (world.world-has? w a :kind))
        (let [tgt t.target]
          (if (or (= tgt nil) (dead? w tgt))
              (set t.kind :idle)
              (let [(tpx tpy) (movement.entity-pos w tgt)
                    tag (. (. (. w.store :kind) a) :tag)
                    prof (content.attack-of tag)]
                (set t.tx tpx)
                (set t.ty tpy)
                (if (movement.within? w a tpx tpy prof.range)
                    (let [cd (world.world-get w a :cooldown)]
                      (when (and cd (= cd.ticks 0))
                        (strike! w a tgt)
                        (set cd.ticks prof.cooldown)))
                    (movement.step-toward! w a tpx tpy)))))))))

{: combat-system : attack-damage}
