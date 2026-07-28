-- Aurelius: Fennel + LÖVE bootstrap
-- Load the embedded Fennel compiler and require the main game module
_G.fennel = require("lib.fennel")
table.insert(package.loaders or package.searchers, fennel.make_searcher({correlate = true}))

-- Pretty-printer for REPL debugging
_G.pp = function(x)
  local view = require("lib.fennelview")
  print(view(x))
end

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
