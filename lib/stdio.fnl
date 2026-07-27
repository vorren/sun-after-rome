;; lib/stdio --- file-based REPL for LÖVE.
;; Polls repl.in each frame, evaluates Fennel expressions, writes to repl.out.
;; Game world modules are injected into the evaluation environment.
;;
;; Usage:
;;   echo '(world.world-query game-world :kind)' > repl.in
;;   cat repl.out
;;
;; Or use the helper script:
;;   ./repl.sh

(local fennel (require :lib.fennel))

(var eval-env nil)
(var pending nil)
(var last-read-mtime 0)

(fn init-env! [w]
  "Build the evaluation environment with game world access."
  (set eval-env
       (setmetatable
        {:game-world w
         :world (require :src.world)
         :sim (require :src.sim)
         :orders (require :src.orders)
         :content (require :src.content)
         :combat (require :src.systems.combat)
         :movement (require :src.systems.movement)
         :gather (require :src.systems.gather)
         :production (require :src.systems.production)}
        {:__index _G})))

(fn eval [code]
  "Evaluate a Fennel string in the REPL environment."
  (when (not eval-env)
    (error "REPL environment not initialized. Call init-env! first."))
  (let [(ok result) (pcall (fn [] (fennel.eval code {:env eval-env})))]
    (if ok
        (if (= (type result) :nil) "nil"
            result)
        (.. "ERROR: " (tostring result)))))

(fn start []
  "Start the REPL. Creates repl.in and repl.out files."
  ;; Clear old files
  (let [f (io.open "repl.in" "w")]
    (when f (f.close f)))
  (let [f (io.open "repl.out" "w")]
    (when f (f.close f)))
  (print "REPL ready. Type Fennel expressions in repl.in, read results in repl.out.")
  (print "Or use: ./repl.sh"))

(fn poll []
  "Called each love.update. Checks repl.in for new expressions."
  (let [f (io.open "repl.in" "r")]
    (when f
      (let [content (f.read f "*a")]
        (f.close f)
        ;; Truncate repl.in
        (let [wf (io.open "repl.in" "w")]
          (when wf (wf.close wf)))
        ;; Process each line
        (when (and content (> (# content) 0))
          (let [out (io.open "repl.out" "a")]
            (each [line (content:gmatch "[^\n]+")]
              (when (> (# line) 0)
                (let [result (eval line)]
                  (out.write out (.. line "\n"))
                  (out.write out (.. result "\n")))))
            (out.close out)))))))

(fn stop []
  "Stop the REPL."
  nil)

{: start : poll : stop : init-env! : eval}
