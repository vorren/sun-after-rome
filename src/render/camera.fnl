;; aurelius.render.camera --- viewport position for scrolling.
;; Holds the screen offset that determines what part of the world is visible.

(var offset-x 640)
(var offset-y 100)

(fn get-offset []
  "Get current camera offset."
  (values offset-x offset-y))

(fn set-offset! [x y]
  "Set camera offset."
  (set offset-x x)
  (set offset-y y))

(fn scroll-to-tile [tile-x tile-y tile-w tile-h screen-w screen-h]
  "Scroll camera so that (tile-x, tile-y) is at screen center."
  (let [(raw-sx raw-sy) (let [hw (/ tile-w 2)
                               hh (/ tile-h 2)]
                           (values (* (- tile-x tile-y) hw)
                                   (* (+ tile-x tile-y) hh)))]
    (set offset-x (- (/ screen-w 2) raw-sx))
    (set offset-y (- (/ screen-h 2) raw-sy))))

(fn reset []
  "Reset camera to default position."
  (set offset-x 640)
  (set offset-y 100))

{: get-offset : set-offset! : scroll-to-tile : reset}
