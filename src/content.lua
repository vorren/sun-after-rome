-- aurelius.content --- static game data: unit/building stats, costs, age bonuses.
-- Pure data + lookup helpers. ADR-0003/0008/0011.

local resource_types = {"wood", "stone", "gold"}

-- Kind table: each entry maps tag -> stat plist
local kinds = {
  ["town-centre"]  = {["max-hp"] = 600, trains = {"villager"}, blocks = true},
  ["barracks"]     = {["max-hp"] = 350, trains = {"knight", "pikeman", "archer"}, blocks = true},
  ["villager"]     = {["max-hp"] = 40, cost = {wood = 25}, ["train-time"] = 25, speed = 1,
                      ["gather-rate"] = 1, ["gather-capacity"] = 10, ["collision-radius"] = 0.3},
  ["knight"]       = {["max-hp"] = 100, cost = {wood = 20, gold = 75}, ["train-time"] = 30, speed = 2,
                      damage = 10, range = 1, armour = "cavalry", ["bonus-vs"] = {}, cooldown = 10,
                      ["collision-radius"] = 0.4},
  ["pikeman"]      = {["max-hp"] = 55, cost = {wood = 25, stone = 10}, ["train-time"] = 22, speed = 1,
                      damage = 4, range = 1, armour = "infantry", ["bonus-vs"] = {cavalry = 15}, cooldown = 10,
                      ["collision-radius"] = 0.3},
  ["archer"]       = {["max-hp"] = 30, cost = {wood = 25, gold = 45}, ["train-time"] = 27, speed = 1,
                      damage = 4, range = 4, armour = "archer", ["bonus-vs"] = {infantry = 3}, cooldown = 14,
                      ["collision-radius"] = 0.3},
  ["tree"]         = {node = "wood", amount = 100},
  ["gold-mine"]    = {node = "gold", amount = 80},
  ["stone-mine"]   = {node = "stone", amount = 80},
}

local function kind_stats(tag)
  return kinds[tag] or error("unknown kind: " .. tostring(tag))
end

local function kind_stat(tag, key, default)
  local stats = kind_stats(tag)
  return stats[key] or default
end

local function base_max_hp(tag) return kind_stat(tag, "max-hp", 1) end
local function unit_cost(tag) return kind_stat(tag, "cost", {}) end
local function train_time(tag) return kind_stat(tag, "train-time", 1) end
local function gather_capacity(tag) return kind_stat(tag, "gather-capacity", 0) end
local function gather_resource(tag) return kind_stat(tag, "node", nil) end
local function producer_trains(tag) return kind_stat(tag, "trains", {}) end

local function attack_of(tag)
  return {
    damage = kind_stat(tag, "damage", 0),
    range = kind_stat(tag, "range", 0),
    armour = kind_stat(tag, "armour", "none"),
    ["bonus-vs"] = kind_stat(tag, "bonus-vs", {}),
    bonus_vs = kind_stat(tag, "bonus-vs", {}),
    cooldown = kind_stat(tag, "cooldown", 1),
  }
end

-- Age table (ADR-0011). Bonuses are multipliers applied at read time.
-- Using exact ratios: 23/20, 13/10 etc stored as {numerator, denominator}.
local ages = {
  [1] = {hp = 1, gather = 1, damage = 1, cost = {}, time = 0},
  [2] = {hp = 23 / 20, gather = 2, damage = 23 / 20, cost = {wood = 100, stone = 50}, time = 100},
  [3] = {hp = 13 / 10, gather = 3, damage = 13 / 10, cost = {wood = 200, gold = 100, stone = 100}, time = 150},
}

local function max_age()
  local m = 0
  for k, _ in pairs(ages) do
    if k > m then m = k end
  end
  return m
end

local function age_bonus(level, key)
  local row = ages[level]
  if row then
    return row[key]
  else
    error("no such age: " .. tostring(level))
  end
end

local function age_cost(level) return ages[level].cost end
local function age_time(level) return ages[level].time end

return {
  resource_types = resource_types,
  kind_stat = kind_stat,
  ["kind-stat"] = kind_stat,
  kind_stats = kind_stats,
  unit_cost = unit_cost,
  ["unit-cost"] = unit_cost,
  train_time = train_time,
  gather_capacity = gather_capacity,
  gather_resource = gather_resource,
  attack_of = attack_of,
  producer_trains = producer_trains,
  ["producer-trains"] = producer_trains,
  base_max_hp = base_max_hp,
  age_bonus = age_bonus,
  max_age = max_age,
  ["max-age"] = max_age,
  age_cost = age_cost,
  ["age-cost"] = age_cost,
  age_time = age_time,
  ["age-time"] = age_time,
  kinds = kinds,
}
