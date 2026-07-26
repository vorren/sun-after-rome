;; aurelius.rng --- deterministic PRNG carried inside the world.
;; ADR-0006: Linear congruential generator, Numerical Recipes constants.

(fn make-rng [seed]
  (let [s (math.abs (or seed 1))]
    {:state (math.fmod s 2147483647)}))

(fn rng-state [rng]
  rng.state)

(fn rng-next! [rng]
  (let [s (math.fmod (+ (* 1103515245 rng.state) 12345) 2147483648)]
    (set rng.state s)
    s))

(fn rng-below! [rng n]
  (if (<= n 1)
      0
      (math.fmod (math.floor (/ (rng-next! rng) 65536)) n)))

(fn rng-range! [rng lo hi]
  (+ lo (rng-below! rng (+ 1 (- hi lo)))))

{: make-rng : rng-state : rng-next! : rng-below! : rng-range!}
