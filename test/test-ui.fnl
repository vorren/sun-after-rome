;; test/test-ui.fnl --- Tests for the UI module.

(local luaunit (require :luaunit))
(local theme (require :src.render.ui.theme))

{:test-hex-to-rgb-converts-hex
 (fn []
   (let [result (theme.hex-to-rgb "#F5E6C8")]
     (luaunit.assertNotNil result)
     (luaunit.assertEquals (type result) :table)
     (luaunit.assertEquals (# result) 3)))

 :test-resolve-color-accepts-hex
 (fn []
   (let [result (theme.resolve-color "#D4A017")]
     (luaunit.assertNotNil result)
     (luaunit.assertEquals (type result) :table)))

 :test-resolve-color-passes-through-tables
 (fn []
   (let [input [0.5 0.5 0.5]
         result (theme.resolve-color input)]
     (luaunit.assertEquals result input)))

 :test-make-theme-creates-a-theme
 (fn []
   (let [t (theme.make-theme {})]
     (luaunit.assertNotNil t)
     (luaunit.assertNotNil t.parchment)
     (luaunit.assertNotNil t.terracotta)
     (luaunit.assertNotNil t.gold)))

 :test-make-theme-accepts-overrides
 (fn []
   (let [t (theme.make-theme {:parchment "#FFFFFF"})]
     (luaunit.assertNotNil t)
     (luaunit.assertNotNil t.parchment)))

 :test-hex-to-rgb-black
 (fn []
   (let [result (theme.hex-to-rgb "#000000")]
     (luaunit.assertEquals (. result 1) 0)
     (luaunit.assertEquals (. result 2) 0)
     (luaunit.assertEquals (. result 3) 0)))

 :test-hex-to-rgb-white
 (fn []
   (let [result (theme.hex-to-rgb "#FFFFFF")]
     (luaunit.assertEquals (. result 1) 1)
     (luaunit.assertEquals (. result 2) 1)
     (luaunit.assertEquals (. result 3) 1)))}
