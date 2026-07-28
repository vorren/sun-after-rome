;; aurelius.render.sprite-sheet --- loads and caches sprite sheets from filesystem.
;; Handles frame numbering, direction mapping, and mirroring.

(local log (require :src.log))

;; Cache for loaded images
(var cache {})

;; Direction constants
(local directions
  {:south       0
   :south-west  1
   :west        2
   :north-west  3
   :north       4
   :north-east  5
   :east        6
   :south-east  7})

(local frames-per-direction 15)

(fn direction-index [frame]
  "Get direction index (0-7) from frame number (0-based)."
  (math.floor (/ frame frames-per-direction)))

(fn needs-mirror? [frame]
  "Check if this frame needs horizontal mirroring (directions 5-7)."
  (>= (direction-index frame) 5))

(fn mirror-direction [frame]
  "Get the mirrored source direction for directions 5-7.
   North East (5) mirrors North West (3)
   East (6) mirrors West (2)
   South East (7) mirrors South West (1)"
  (let [idx (direction-index frame)]
    (if (= idx 5) 3  ;; NE mirrors NW
        (= idx 6) 2  ;; E mirrors W
        (= idx 7) 1  ;; SE mirrors SW
        idx)))

(fn frame-number [frame]
  "Get the frame number within a direction (0-14)."
  (% frame frames-per-direction))

(fn load-sprite [path]
  "Load a single sprite image, with caching."
  (or (. cache path)
      (let [(ok img) (pcall love.graphics.newImage path)]
        (if ok
            (do
              (tset cache path img)
              img)
            (do
              (log.warn :sprite-sheet (.. "Failed to load: " path))
              nil)))))

(fn load-animation [directory prefix count]
  "Load a sequence of sprites from a directory.
   Files should be named: {prefix}001.png, {prefix}002.png, etc.
   Returns a table of images indexed by frame number (1-based)."
  (let [sprites []]
    (for [i 1 count]
      (let [num (string.format "%03d" i)
            path (.. directory "/" prefix num ".png")
            img (load-sprite path)]
        (table.insert sprites img)))
    sprites))

(fn get-frame [sprites frame]
  "Get the correct sprite for a given animation frame (0-based).
   Handles direction mapping and mirroring.
   sprites: table of loaded images (5 directions × 15 frames = 75 images)
   frame: animation frame number (0-based, 0-119 for 8 directions)"
  (let [idx (direction-index frame)
        fnum (frame-number frame)
        source-idx (if (>= idx 5)
                       (mirror-direction frame)
                       idx)
        ;; convert to 1-based index for Lua table
        source-frame (+ (* source-idx frames-per-direction) fnum 1)
        img (. sprites source-frame)]
    {:image img
     :mirror (needs-mirror? frame)}))

(fn clear-cache []
  "Clear the sprite cache."
  (set cache {})
  (log.info :sprite-sheet "Cache cleared"))

{: directions : frames-per-direction
 : load-animation : get-frame : clear-cache
 : direction-index : needs-mirror? : frame-number}
