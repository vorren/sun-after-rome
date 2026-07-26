;; aurelius.render.iso --- isometric coordinate transforms.

(fn to-screen [tile-x tile-y tile-w tile-h]
  (values (* (- tile-x tile-y) (/ tile-w 2))
          (* (+ tile-x tile-y) (/ tile-h 2))))

(fn to-tile [screen-x screen-y tile-w tile-h]
  (let [hw (/ tile-w 2)
        hh (/ tile-h 2)]
    (values (/ (+ (/ screen-x hw) (/ screen-y hh)) 2)
            (/ (- (/ screen-y hh) (/ screen-x hw)) 2))))

(fn depth-key [tile-x tile-y]
  (+ tile-y (* tile-x 1000)))

{: to-screen : to-tile : depth-key}
