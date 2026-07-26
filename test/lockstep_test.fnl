;; Test: Command serialization
(local luaunit (require :luaunit))
(local commands (require :src.net.commands))

{:test-serialize-deserialize-move
 (fn []
   (let [cmd {:tag :move :eid 5 :tx 10 :ty 8}
         serialized (commands.serialize-order cmd)
         deserialized (commands.deserialize-order serialized)]
     (luaunit.assertEquals deserialized.tag :move)
     (luaunit.assertEquals deserialized.eid 5)
     (luaunit.assertEquals deserialized.tx 10)
     (luaunit.assertEquals deserialized.ty 8)))

 :test-serialize-deserialize-gather
 (fn []
   (let [cmd {:tag :gather :eid 3 :node 7}
         serialized (commands.serialize-order cmd)
         deserialized (commands.deserialize-order serialized)]
     (luaunit.assertEquals deserialized.tag :gather)
     (luaunit.assertEquals deserialized.eid 3)
     (luaunit.assertEquals deserialized.node 7)))

 :test-serialize-deserialize-commands
 (fn []
   (let [cmds [{:tag :move :eid 1 :tx 5 :ty 5}
               {:tag :gather :eid 2 :node 3}]
         serialized (commands.serialize-commands cmds)
         deserialized (commands.deserialize-commands serialized)]
     (luaunit.assertEquals (# deserialized) 2)
     (luaunit.assertEquals (. deserialized 1 :tag) :move)
     (luaunit.assertEquals (. deserialized 2 :tag) :gather)))}
