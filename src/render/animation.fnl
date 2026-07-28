;; aurelius.render.animation --- frame-based animation system.
;; Tracks current frame, speed, and looping for sprite animations.

(local sprite-sheet (require :src.render.sprite-sheet))

(fn make-animation [sprites speed looping]
  "Create a new animation.
   sprites: table of loaded images from sprite-sheet.load-animation
   speed: frames per second (default: 15 for AoE2 style)
   looping: whether to loop (default: true)"
  {:sprites sprites
   :speed (or speed 15)
   :looping (if (= looping nil) true looping)
   :current-frame 0
   :elapsed 0
   :total-frames (* 5 sprite-sheet.frames-per-direction)  ;; 5 directions × 15 frames
   :playing true})

(fn update [anim dt]
  "Advance animation by dt seconds."
  (when anim.playing
    (set anim.elapsed (+ anim.elapsed dt))
    (let [frame-duration (/ 1 anim.speed)]
      (while (>= anim.elapsed frame-duration)
        (set anim.elapsed (- anim.elapsed frame-duration))
        (set anim.current-frame (+ anim.current-frame 1))
        ;; handle end of animation
        (when (>= anim.current-frame anim.total-frames)
          (if anim.looping
              (set anim.current-frame 0)
              (do
                (set anim.current-frame (- anim.total-frames 1))
                (set anim.playing false))))))))

(fn get-sprite [anim entity-direction]
  "Get the current sprite for drawing.
   entity-direction: direction the entity is facing (0-7, from iso.depth-key or task)
   Returns: {:image img :mirror bool}"
  ;; combine animation frame with entity direction
  ;; animation frame provides the walk cycle (0-14 within direction)
  ;; entity direction provides which direction set to use
  (let [walk-frame (% anim.current-frame sprite-sheet.frames-per-direction)
        frame (+ (* entity-direction sprite-sheet.frames-per-direction) walk-frame)]
    (sprite-sheet.get-frame anim.sprites frame)))

(fn reset [anim]
  "Reset animation to frame 0."
  (set anim.current-frame 0)
  (set anim.elapsed 0)
  (set anim.playing true))

(fn play [anim]
  "Start playing animation."
  (set anim.playing true))

(fn pause [anim]
  "Pause animation."
  (set anim.playing false))

(fn set-speed [anim speed]
  "Set animation speed in frames per second."
  (set anim.speed speed))

{: make-animation : update : get-sprite : reset : play : pause : set-speed}
