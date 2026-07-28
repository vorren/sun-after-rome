-- Test: Command serialization
local luaunit = require("luaunit")
local commands = require("src.net.commands")

return {
  ["test-serialize-deserialize-move"] = function()
    local cmd = {tag = "move", eid = 5, tx = 10, ty = 8}
    local serialized = commands.serialize_order(cmd)
    local deserialized = commands.deserialize_order(serialized)
    luaunit.assertEquals(deserialized.tag, "move")
    luaunit.assertEquals(deserialized.eid, 5)
    luaunit.assertEquals(deserialized.tx, 10)
    luaunit.assertEquals(deserialized.ty, 8)
  end,

  ["test-serialize-deserialize-gather"] = function()
    local cmd = {tag = "gather", eid = 3, node = 7}
    local serialized = commands.serialize_order(cmd)
    local deserialized = commands.deserialize_order(serialized)
    luaunit.assertEquals(deserialized.tag, "gather")
    luaunit.assertEquals(deserialized.eid, 3)
    luaunit.assertEquals(deserialized.node, 7)
  end,

  ["test-serialize-deserialize-commands"] = function()
    local cmds = {{tag = "move", eid = 1, tx = 5, ty = 5}, {tag = "gather", eid = 2, node = 3}}
    local serialized = commands.serialize_commands(cmds)
    local deserialized = commands.deserialize_commands(serialized)
    luaunit.assertEquals(#deserialized, 2)
    luaunit.assertEquals(deserialized[1].tag, "move")
    luaunit.assertEquals(deserialized[2].tag, "gather")
  end,
}
