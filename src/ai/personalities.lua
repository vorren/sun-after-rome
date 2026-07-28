-- src.ai.personalities --- data-driven AI personality configs.
-- Controls aggression, resource ratios, and military thresholds.
-- ADR-0016: personality is a data table, not logic.

local personalities = {
  aggressive = {
    name = "aggressive",
    ["villager-target"] = 6,
    ["wood-ratio"] = 0.4,
    ["food-ratio"] = 0.4,
    ["gold-ratio"] = 0.2,
    ["stone-ratio"] = 0.0,
    ["military-threshold"] = 3,
    ["attack-when-idle"] = true,
  },
  defensive = {
    name = "defensive",
    ["villager-target"] = 8,
    ["wood-ratio"] = 0.3,
    ["food-ratio"] = 0.3,
    ["gold-ratio"] = 0.2,
    ["stone-ratio"] = 0.2,
    ["military-threshold"] = 5,
    ["attack-when-idle"] = false,
  },
  balanced = {
    name = "balanced",
    ["villager-target"] = 7,
    ["wood-ratio"] = 0.35,
    ["food-ratio"] = 0.35,
    ["gold-ratio"] = 0.2,
    ["stone-ratio"] = 0.1,
    ["military-threshold"] = 4,
    ["attack-when-idle"] = true,
  },
}

-- Get personality config by NAME, or error if not found.
local function get_personality(name)
  return personalities[name]
    or error("unknown personality: " .. tostring(name))
end

-- The v1 default: aggressive.
local function default_personality()
  return personalities["aggressive"]
end

return {
  personalities = personalities,
  ["get-personality"] = get_personality,
  get_personality = get_personality,
  ["default-personality"] = default_personality,
  default_personality = default_personality,
}
