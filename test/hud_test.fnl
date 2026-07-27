;; Test: HUD module
(local luaunit (require :luaunit))

{:test-hud-compiles-correctly
 (fn []
   (let [hud (require :src.render.hud)]
     (luaunit.assertNotNil hud.draw-hud)
     (luaunit.assertNotNil hud.handle-click)
     (luaunit.assertNotNil hud.set-selection!)
     (luaunit.assertNotNil hud.get-selection)
     (luaunit.assertNotNil hud.draw-selection-highlight)))

 :test-hud-uses-correct-love-api
 (fn []
   (let [f (io.open "src/render/hud.fnl" "r")
         content (f:read "*a")]
     (f:close)
     (luaunit.assertNotNil (string.find content "love%.graphics%.setLineWidth"))
     (luaunit.assertNil (string.find content "love%.graphics%.set%-line%-width"))))}
