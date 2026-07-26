;; Test: Isometric coordinate transforms
(local luaunit (require :luaunit))
(local iso (require :src.render.iso))

{:test-to-screen-and-back
 (fn []
   (let [tile-w 64 tile-h 32]
     ;; Round-trip should preserve coordinates
     (for [x 0 10]
       (for [y 0 10]
         (let [(sx sy) (iso.to-screen x y tile-w tile-h)
               (tx ty) (iso.to-tile sx sy tile-w tile-h)]
           ;; Allow small floating point error
           (luaunit.assertAlmostEquals tx x 0.001)
           (luaunit.assertAlmostEquals ty y 0.001))))))

 :test-depth-key-ordering
 (fn []
   ;; Entities further back should have lower depth keys
   (let [k1 (iso.depth-key 0 0)
         k2 (iso.depth-key 1 0)
         k3 (iso.depth-key 0 1)]
     (luaunit.assertTrue (< k1 k2))
     (luaunit.assertTrue (< k1 k3))))}
