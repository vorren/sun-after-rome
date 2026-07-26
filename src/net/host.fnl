;; aurelius.net.host --- ENet host/client setup for LAN multiplayer.
;; Wraps lua-enet for connection management.

(local commands (require :src.net.commands))
(local lockstep (require :src.net.lockstep))

(var enet nil)
(var host nil)
(var peer nil)
(var connected-peers {})
(var connected false)

(fn init-host! [port]
  (set enet (require :enet))
  (set host (enet.host_create (.. "*" (tostring (or port 6789)))))
  (set connected true)
  (print (.. "Listening on port " (tostring (or port 6789)))))

(fn connect! [address port]
  (set enet (require :enet))
  (set host (enet.host_create))
  (set peer (host:connect (.. (tostring address) ":" (tostring (or port 6789)))))
  (print (.. "Connecting to " address ":" (tostring (or port 6789)))))

(fn poll! []
  (when host
    (var event (host:service 0))
    (while event
      (match event.type
        :connect
        (do
          (print "Peer connected")
          (tset connected-peers event.peer true)
          (set connected true))

        :disconnect
        (do
          (print "Peer disconnected")
          (tset connected-peers event.peer nil)
          (when (= (length (pairs connected-peers)) 0)
            (set connected false)))

        :receive
        (let [data (tostring event.data)
              cmds (commands.deserialize-commands data)]
          (lockstep.receive-remote-commands! cmds)))
      (set event (host:service 0)))))

(fn send-commands! [cmds]
  (when (and host connected)
    (let [data (commands.serialize-commands cmds)]
      (when (> (# data) 0)
        (each [peer _ (pairs connected-peers)]
          (peer:send data 0 :reliable))))))

(fn disconnect! []
  (when host
    (each [p _ (pairs connected-peers)]
      (p:disconnect))
    (host:flush)
    (set host nil)
    (set connected-peers {})
    (set connected false)))

(fn is-connected? [] connected)

{: init-host! : connect! : poll! : send-commands! : disconnect! : is-connected?}
