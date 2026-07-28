-- aurelius.log --- logging system with verbosity levels.
-- Provides structured logging for game events, debugging, and diagnostics.

local log_level = "info"
local log_buffer = {}
local log_callback = nil

local levels = {
  debug = 0,
  info = 1,
  warn = 2,
  error = 3,
}

local function set_level(level)
  log_level = level
end

local function get_level()
  return log_level
end

local function set_callback(callback)
  log_callback = callback
end

local function should_log(level)
  return (levels[level] or 0) >= (levels[log_level] or 0)
end

local function format_msg(level, tag, msg)
  return "[" .. string.upper(level) .. "] " .. tag .. ": " .. msg
end

local function log(level, tag, msg)
  if should_log(level) then
    local formatted = format_msg(level, tag, msg)
    table.insert(log_buffer, { level = level, tag = tag, msg = msg, formatted = formatted })
    if #log_buffer > 1000 then
      table.remove(log_buffer, 1)
    end
    print(formatted)
    if log_callback then
      log_callback(level, tag, msg)
    end
  end
end

local function debug(tag, msg)
  log("debug", tag, msg)
end

local function info(tag, msg)
  log("info", tag, msg)
end

local function warn(tag, msg)
  log("warn", tag, msg)
end

local function error_log(tag, msg)
  log("error", tag, msg)
end

local function get_buffer()
  return log_buffer
end

local function get_recent(n)
  local result = {}
  local i = math.max(1, #log_buffer - (n or 10))
  while i <= #log_buffer do
    table.insert(result, log_buffer[i])
    i = i + 1
  end
  return result
end

local function clear_buffer()
  log_buffer = {}
end

local function save_to_file(filename)
  local f = io.open(filename, "w")
  if f then
    for _, entry in ipairs(log_buffer) do
      f:write(entry.formatted .. "\n")
    end
    f:close()
    print("Log saved to " .. filename)
  end
end

return {
  set_level = set_level,
  get_level = get_level,
  set_callback = set_callback,
  debug = debug,
  info = info,
  warn = warn,
  error_log = error_log,
  get_buffer = get_buffer,
  get_recent = get_recent,
  clear_buffer = clear_buffer,
  save_to_file = save_to_file,
}
