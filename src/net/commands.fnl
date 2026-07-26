;; aurelius.net.commands --- command serialization for network transport.
;; Commands are already data (tagged tables); serialize via string operations.

(fn serialize-order [order]
  (match order.tag
    :move       (string.format "m:%d:%d:%d" order.eid order.tx order.ty)
    :gather     (string.format "g:%d:%d" order.eid order.node)
    :attack     (string.format "a:%d:%d" order.eid order.target)
    :train      (string.format "t:%d:%s" order.prod order.unit)
    :advance-age (string.format "u:%d" order.player)
    _ ""))

;; Split a string by a delimiter (since Fennel doesn't like str:gsub)
(fn split [str delim]
  (let [result {}]
    (var start 1)
    (var done false)
    (while (not done)
      (let [pos (string.find str delim start true)]
        (if pos
            (do
              (table.insert result (string.sub str start (- pos 1)))
              (set start (+ pos 1)))
            (do
              (table.insert result (string.sub str start))
              (set done true)))))
    result))

(fn deserialize-order [str]
  (let [parts (split str ":")
        tag (. parts 1)]
    (match tag
      :m {:tag :move :eid (tonumber (. parts 2)) :tx (tonumber (. parts 3)) :ty (tonumber (. parts 4))}
      :g {:tag :gather :eid (tonumber (. parts 2)) :node (tonumber (. parts 3))}
      :a {:tag :attack :eid (tonumber (. parts 2)) :target (tonumber (. parts 3))}
      :t {:tag :train :prod (tonumber (. parts 2)) :unit (. parts 3)}
      :u {:tag :advance-age :player (tonumber (. parts 2))}
      _ nil)))

(fn serialize-commands [cmds]
  (let [parts {}]
    (each [_ cmd (ipairs cmds)]
      (let [s (serialize-order cmd)]
        (when (> (# s) 0)
          (table.insert parts s))))
    (table.concat parts "|")))

(fn deserialize-commands [str]
  (let [cmds {}]
    (when (and str (> (# str) 0))
      (let [parts (split str "|")]
        (each [_ s (ipairs parts)]
          (let [cmd (deserialize-order s)]
            (when cmd (table.insert cmds cmd))))))
    cmds))

{: serialize-order : deserialize-order : serialize-commands : deserialize-commands}
