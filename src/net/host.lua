-- aurelius.net.host --- ENet host/client setup for LAN multiplayer.
-- Wraps lua-enet for connection management.

local commands = require("src.net.commands")
local lockstep = require("src.net.lockstep")

local enet = nil
local host = nil
local peer = nil
local connected_peers = {}
local connected = false

local function init_host(port)
  enet = require("enet")
  host = enet.host_create("*" .. tostring(port or 6789))
  connected = true
  print("Listening on port " .. tostring(port or 6789))
end

local function connect(address, port)
  enet = require("enet")
  host = enet.host_create()
  peer = host:connect(tostring(address) .. ":" .. tostring(port or 6789))
  print("Connecting to " .. address .. ":" .. tostring(port or 6789))
end

local function poll()
  if host then
    local event = host:service(0)
    while event do
      if event.type == "connect" then
        print("Peer connected")
        connected_peers[event.peer] = true
        connected = true
      elseif event.type == "disconnect" then
        print("Peer disconnected")
        connected_peers[event.peer] = nil
        if next(connected_peers) == nil then
          connected = false
        end
      elseif event.type == "receive" then
        local data = tostring(event.data)
        local cmds = commands.deserialize_commands(data)
        lockstep.receive_remote_commands(cmds)
      end
      event = host:service(0)
    end
  end
end

local function send_commands(cmds)
  if host and connected then
    local data = commands.serialize_commands(cmds)
    if #data > 0 then
      for peer_key, _ in pairs(connected_peers) do
        peer_key:send(data, 0, "reliable")
      end
    end
  end
end

local function disconnect()
  if host then
    for p, _ in pairs(connected_peers) do
      p:disconnect()
    end
    host:flush()
    host = nil
    connected_peers = {}
    connected = false
  end
end

local function is_connected()
  return connected
end

return {
  init_host = init_host,
  connect = connect,
  poll = poll,
  send_commands = send_commands,
  disconnect = disconnect,
  is_connected = is_connected,
}
