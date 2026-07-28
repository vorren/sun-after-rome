-- aurelius.rng --- deterministic PRNG carried inside the world.
-- ADR-0006: Linear congruential generator, Numerical Recipes constants.

local function make_rng(seed)
  local s = math.abs(seed or 1)
  return {state = math.fmod(s, 2147483647)}
end

local function rng_state(rng)
  return rng.state
end

local function rng_next(rng)
  local s = math.fmod((1103515245 * rng.state) + 12345, 2147483648)
  rng.state = s
  return s
end

local function rng_below(rng, n)
  if n <= 1 then
    return 0
  end
  return math.fmod(math.floor(rng_next(rng) / 65536), n)
end

local function rng_range(rng, lo, hi)
  return lo + rng_below(rng, 1 + (hi - lo))
end

return {
  ["make-rng"] = make_rng,
  ["rng-state"] = rng_state,
  ["rng-next!"] = rng_next,
  ["rng-below!"] = rng_below,
  ["rng-range!"] = rng_range,
}
