-- Sun After Rome: LÖVE bootstrap
-- Load the main game module

-- Check for smoke test flag
local smoke_test = false
for _, arg in ipairs(arg or {}) do
  if arg == "--smoke-test" then
    smoke_test = true
    break
  end
end

-- Load appropriate module
if smoke_test then
  require("test.smoke_test")
else
  require("src.init")
end
