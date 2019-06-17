local room = {}

room.empty = function(surface, cell_left_top, direction)
	
end

room.stone_block = function(surface, cell_left_top, direction)	
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 2.5, grid_size * 2 - 2.5, 1 do
		for y = 2.5, grid_size * 2 - 2.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}			
			if math.random(1,6) ~= 1 then surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = pos, force = "neutral"}) end
		end
	end
	
	for a = 1, math.random(1, 2), 1 do
		local chest = surface.create_entity({
			name = "steel-chest",
			position = {left_top.x + math.random(math.floor(grid_size * 0.5), math.floor(grid_size * 1.5)), left_top.y + math.random(math.floor(grid_size * 0.5), math.floor(grid_size * 1.5))},
			force = "neutral",
		})
		for a = 1, math.random(1, 3), 1 do
			chest.insert(get_loot_item_stack())
		end
	end
end

room.scrapyard = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}	
	for x = 2.5, grid_size * 2 - 2.5, 1 do
		for y = 2.5, grid_size * 2 - 2.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}			
			if math.random(1,3) == 1 then surface.create_entity({name = "mineable-wreckage", position = pos, force = "neutral"}) end
		end
	end
	local e = surface.create_entity({name = "storage-tank", position = {left_top.x + grid_size, left_top.y + grid_size}, force = "neutral", direction = math.random(0, 3)})
	local fluids = {"crude-oil", "lubricant", "heavy-oil", "light-oil", "petroleum-gas", "sulfuric-acid", "water"}
	e.fluidbox[1] = {name = fluids[math.random(1, #fluids)], amount = math.random(20000, 25000)}
end

room.circle_pond_with_trees = function(surface, cell_left_top, direction)
	local tree = tree_raffle[math.random(1, #tree_raffle)]
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	local center_pos = {x = left_top.x + grid_size, y = left_top.y + grid_size}
	
	map_functions.draw_noise_tile_circle({x = left_top.x + grid_size, y = left_top.y + grid_size}, "grass-2", surface, grid_size * 0.75)
	map_functions.draw_noise_tile_circle({x = left_top.x + grid_size, y = left_top.y + grid_size}, "water", surface, grid_size * 0.5)
		
	for x = math.floor(grid_size * 2 * 0.1), math.floor(grid_size * 2 * 0.9), 1 do
		for y = math.floor(grid_size * 2 * 0.1), math.floor(grid_size * 2 * 0.9), 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			local distance_to_center = math.sqrt((center_pos.x - pos.x) ^ 2 + (center_pos.y - pos.y) ^ 2)
			if math.random(1,5) == 1 and distance_to_center < grid_size * 0.85 then
				if surface.can_place_entity({name = tree, position = pos, force = "neutral"}) then surface.create_entity({name = tree, position = pos, force = "neutral"}) end
			end
			if math.random(1,16) == 1 then
				if surface.can_place_entity({name = "fish", position = pos, force = "neutral"}) then
					surface.create_entity({name = "fish", position = pos, force = "neutral"})
				end
			end
		end
	end
end

room.checkerboard_ore = function(surface, cell_left_top, direction)
	local ores = {"coal", "iron-ore", "copper-ore", "stone"}
	table.shuffle_table(ores)
	
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 4, grid_size * 2 - 5, 1 do
		for y = 4, grid_size * 2 - 5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if x % 2 == y % 2 then
				surface.create_entity({name = ores[1], position = pos, force = "neutral", amount = get_ore_amount()})
			else
				surface.create_entity({name = ores[2], position = pos, force = "neutral", amount = get_ore_amount()})
			end
			surface.set_tiles({{name = "grass-2", position = pos}}, true)
		end
	end
	
	for x = 1, grid_size * 2 - 1, 1 do
		for y = 1, grid_size * 2 - 1, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if x <= 3 or x >= grid_size * 2 - 3 or y <= 3 or y >= grid_size * 2 - 3 then
				if math.random(1,3) ~= 1 then surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = pos, force = "neutral"}) end
			end
		end
	end
end

room.minefield_chest = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	
	local chest = surface.create_entity({
		name = "steel-chest",
		position = {left_top.x + grid_size + (direction[1] * grid_size * 0.5), left_top.y + grid_size + (direction[2] * grid_size * 0.5)},
		force = "neutral",
	})
	
	chest.insert(get_loot_item_stack())
	chest.insert(get_loot_item_stack())
	chest.insert(get_loot_item_stack())
	chest.insert(get_loot_item_stack())
	chest.insert(get_loot_item_stack())
	chest.insert(get_loot_item_stack())
	
	for x = 0, grid_size * 2 - 1, 1 do
		for y = 0, grid_size * 2 - 1, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if x <= 1 or x >= grid_size * 2 - 2 or y <= 1 or y >= grid_size * 2 - 2 then
				surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = pos, force = "neutral"})
			else
				if x == 2 or x == grid_size * 2 - 3 or y == 2 or y == grid_size * 2 - 3 then
					surface.create_entity({name = "stone-wall", position = pos, force = "enemy"})
				else
					if math.random(1,6) == 1 then
						surface.create_entity({name = "land-mine", position = pos, force = "enemy"})
					end
				end				
			end
		end
	end
end

local room_weights = {
	{func = room.circle_pond_with_trees, weight = 25},	
	{func = room.scrapyard, weight = 10},
	{func = room.stone_block, weight = 25},
	{func = room.minefield_chest, weight = 5},
	{func = room.checkerboard_ore, weight = 10}
}

local room_shuffle = {}
for _, r in pairs(room_weights) do
	for c = 1, r.weight, 1 do
		room_shuffle[#room_shuffle + 1] = r.func
	end
end


return room_shuffle