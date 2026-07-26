;; Test: RNG determinism
(local luaunit (require :luaunit))
(local rng (require :src.rng))

{:test-rng-determinism
 (fn []
   (let [r1 (rng.make-rng 42)
         r2 (rng.make-rng 42)]
     (for [_ 1 100]
       (luaunit.assertEquals (rng.rng-next! r1) (rng.rng-next! r2)))))

 :test-rng-different-seeds-diverge
 (fn []
   (let [r1 (rng.make-rng 1)
         r2 (rng.make-rng 999)]
     (var same true)
     (for [_ 1 10]
       (when (not= (rng.rng-next! r1) (rng.rng-next! r2))
         (set same false)))
     (luaunit.assertFalse same)))

 :test-rng-below-range
 (fn []
   (let [r (rng.make-rng 42)]
     (for [_ 1 100]
       (let [v (rng.rng-below! r 10)]
         (luaunit.assertTrue (>= v 0))
         (luaunit.assertTrue (< v 10))))))

 :test-rng-range
 (fn []
   (let [r (rng.make-rng 42)]
     (for [_ 1 100]
       (let [v (rng.rng-range! r 5 15)]
         (luaunit.assertTrue (>= v 5))
         (luaunit.assertTrue (<= v 15))))))}
