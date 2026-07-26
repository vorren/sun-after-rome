-- Aurelius: Fennel + LÖVE bootstrap
-- Load the embedded Fennel compiler and require the main game module
_G.fennel = require("lib.fennel")
table.insert(package.loaders or package.searchers, fennel.make_searcher({correlate = true}))

-- Pretty-printer for REPL debugging
_G.pp = function(x)
  local view = require("lib.fennelview")
  print(view(x))
end

-- Load the main Fennel entry point
require("src.init")
