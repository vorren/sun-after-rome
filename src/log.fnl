;; aurelius.log --- logging system with verbosity levels.
;; Provides structured logging for game events, debugging, and diagnostics.

(var log-level :info)
(var log-buffer [])
(var log-callback nil)

(local levels
  {:debug 0
   :info 1
   :warn 2
   :error 3})

(fn set-level [level]
  "Set minimum log level (:debug, :info, :warn, :error)."
  (set log-level level))

(fn get-level []
  "Get current log level."
  log-level)

(fn set-callback [callback]
  "Set callback function for log entries (fn level tag msg)."
  (set log-callback callback))

(fn should-log? [level]
  "Check if LEVEL should be logged."
  (>= (or (. levels level) 0) (or (. levels log-level) 0)))

(fn format-msg [level tag msg]
  "Format a log message."
  (.. "[" (string.upper level) "] " tag ": " msg))

(fn log [level tag msg]
  "Log a message if level is sufficient."
  (when (should-log? level)
    (let [formatted (format-msg level tag msg)]
      (table.insert log-buffer {:level level :tag tag :msg msg :formatted formatted})
      (when (> (# log-buffer) 1000)
        (table.remove log-buffer 1))
      (print formatted)
      (when log-callback
        (log-callback level tag msg)))))

(fn debug [tag msg] (log :debug tag msg))
(fn info [tag msg] (log :info tag msg))
(fn warn [tag msg] (log :warn tag msg))
(fn error-log [tag msg] (log :error tag msg))

(fn get-buffer []
  "Get recent log entries."
  log-buffer)

(fn get-recent [n]
  "Get last N log entries."
  (let [result []]
    (var i (math.max 1 (- (# log-buffer) (or n 10))))
    (while (<= i (# log-buffer))
      (table.insert result (. log-buffer i))
      (set i (+ i 1)))
    result))

(fn clear-buffer []
  "Clear log buffer."
  (set log-buffer []))

(fn save-to-file [filename]
  "Save log buffer to file."
  (let [f (io.open filename "w")]
    (when f
      (each [_ entry (ipairs log-buffer)]
        (f:write (.. entry.formatted "\n")))
      (f:close)
      (print (.. "Log saved to " filename)))))

{: set-level : get-level : set-callback : debug : info : warn : error-log
 : get-buffer : get-recent : clear-buffer : save-to-file}
