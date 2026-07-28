;; aurelius.render.font --- font management.
;; Loads and manages fonts for HUD rendering.

(var font-sm nil)
(var font-md nil)
(var font-lg nil)

(fn load-fonts []
  (set font-sm (love.graphics.newFont 12))
  (set font-md (love.graphics.newFont 16))
  (set font-lg (love.graphics.newFont 24))
  (love.graphics.setFont font-md))

(fn get-font [size]
  (if (= size :sm) font-sm
      (= size :lg) font-lg
      font-md))

{: load-fonts : get-font}
