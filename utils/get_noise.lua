local simplex_noise = require "utils.simplex_noise".d2

--add or use noise templates from here
local noises = {
	["cave_ponds"] = {{modifier = 0.01, weight = 1}, {modifier = 0.1, weight = 0.06}},
	["cave_rivers"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.25}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_2"] = {{modifier = 0.003, weight = 1}, {modifier = 0.01, weight = 0.21}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_3"] = {{modifier = 0.002, weight = 1}, {modifier = 0.01, weight = 0.15}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_4"] = {{modifier = 0.001, weight = 1}, {modifier = 0.01, weight = 0.11}, {modifier = 0.05, weight = 0.01}},
	["large_caves"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},	
	["n1"] = {{modifier = 0.0001, weight = 1}},
	["n2"] = {{modifier = 0.001, weight = 1}},
	["n3"] = {{modifier = 0.01, weight = 1}},
	["n4"] = {{modifier = 0.1, weight = 1}},
	["no_rocks"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},
	["no_rocks_2"] = {{modifier = 0.013, weight = 1}, {modifier = 0.1, weight = 0.1}},
	["oasis"] = {{modifier = 0.0015, weight = 1}, {modifier = 0.0025, weight = 0.5}, {modifier = 0.01, weight = 0.15}, {modifier = 0.1, weight = 0.017}},
	["scrapyard"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.35}, {modifier = 0.05, weight = 0.23}, {modifier = 0.1, weight = 0.11}},
	["small_caves"] = {{modifier = 0.008, weight = 1}, {modifier = 0.03, weight = 0.15}, {modifier = 0.25, weight = 0.05}},
	["small_caves_2"] = {{modifier = 0.009, weight = 1}, {modifier = 0.05, weight = 0.25}, {modifier = 0.25, weight = 0.05}},
}

--returns a float number between -1 and 1
local function get_noise(name, pos, seed)
	local noise = 0
	local d = 0
	for _, n in pairs(noises[name]) do
		noise = noise + simplex_noise(pos.x * n.modifier, pos.y * n.modifier, seed) * n.weight
		d = d + n.weight
		seed = seed + 10000
	end
	noise = noise / d
	return noise		
end

return get_noise