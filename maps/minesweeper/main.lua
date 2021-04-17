--[[
It's a Minesweeper thingy - MewMew
-- 1 to 9 = adjecant mines
-- 10 = mine
-- 11 = marked mine
]]--

require 'modules.satellite_score'

local Map_score = require "comfy_panel.map_score"
local LootRaffle = require "functions.loot_raffle"
local Map = require "modules.map_info"
local Global = require 'utils.global'
local Get_noise = require "utils.get_noise"
local minesweeper = {}
Global.register(
    minesweeper,
    function(tbl)
        minesweeper = tbl
    end
)

local number_colors = {
	[1] = {0, 0, 190},
	[2] = {0, 125, 0},
	[3] = {180, 0, 0},
	[4] = {0, 0, 130},
	[5] = {130, 0, 0},
	[6] = {150, 0, 150},
	[7] = {0, 0, 0},
	[8] = {177, 177, 177},
	[11] = {150, 0, 150},
}

local chunk_divide_vectors = {}
for x = 0, 30, 2 do
	for y = 0, 30, 2 do
		table.insert(chunk_divide_vectors, {x,y})
	end
end
local size_of_chunk_divide_vectors = #chunk_divide_vectors

local chunk_vectors = {}
for x = -32, 32, 32 do
	for y = -32, 32, 32 do
		table.insert(chunk_vectors, {x,y})
	end
end

local cell_update_vectors = {}
for x = -2, 2, 2 do
	for y = -2, 2, 2 do
		table.insert(cell_update_vectors, {x,y})
	end
end

local cell_adjecant_vectors = {}
for x = -2, 2, 2 do
	for y = -2, 2, 2 do
		if x == 0 and y == 0 then
		else
			table.insert(cell_adjecant_vectors, {x,y})
		end
	end
end

local solving_vector_tables = {}
local i = 1
for r = 3, 10, 1 do
	solving_vector_tables[i] = {}
	for x = r * -2, r * 2, 2 do
		for y = r * -2, r * 2, 2 do			
			table.insert(solving_vector_tables[i], {x,y})			
		end
	end
	i = i + 1
end
local size_of_solving_vector_tables = #solving_vector_tables

local ores = {}
for _ = 1, 8, 1 do table.insert(ores, "iron-ore") end
for _ = 1, 6, 1 do table.insert(ores, "copper-ore") end
for _ = 1, 5, 1 do table.insert(ores, "coal") end
for _ = 1, 4, 1 do table.insert(ores, "stone") end
for _ = 1, 1, 1 do table.insert(ores, "uranium-ore") end

local function position_to_string(p)
	return p.x .. "_" .. p.y
end

local function position_to_cell_position(p)
	local cell_position = {}
	cell_position.x = math.floor(p.x * 0.5) * 2
	cell_position.y = math.floor(p.y * 0.5) * 2
	return cell_position
end

local function kaboom(position)
	local surface = game.surfaces[1]
	surface.create_entity({name = "atomic-rocket", position = {position.x + 1, position.y + 1}, target = {position.x + 1, position.y + 1}, speed = 1, force = "minesweeper"})
end

local function disarm_reward(position)
	local surface = game.surfaces[1]
	local distance_to_center = math.sqrt(position.x ^ 2 + position.y ^ 2)
	
	surface.create_entity({
		name = "flying-text",
		position = {position.x + 1, position.y + 1},
		text = "Mine disarmed!",
		color = {r=0.98, g=0.66, b=0.22}
	})
	
	if math.random(1, 3) ~= 1 then return end
	
	if math.random(1, 8) == 1 then
		local blacklist = LootRaffle.get_tech_blacklist(0.05 + distance_to_center * 0.00025)	--max loot tier at ~4000 tiles
		local item_stacks = LootRaffle.roll(math.random(16, 48) + math.floor(distance_to_center * 0.2), 16, blacklist)
		local container = surface.create_entity({name = "crash-site-chest-" .. math.random(1, 2), position = {position.x + math.random(0, 1), position.y + math.random(0, 1)}, force = "neutral"})
		for _, item_stack in pairs(item_stacks) do container.insert(item_stack) end
		container.minable = false
		return
	end
	
	if math.random(1, 32) == 1 then
		surface.create_entity({name = "crude-oil", position = {position.x + 1, position.y + 1}, amount = 301000 + distance_to_center * 300})
		return
	end
	
	local ore = ores[math.random(1, #ores)]
	for x = 0, 1, 1 do
		for y = 0, 1, 1 do
			local p = {x = position.x + x, y = position.y + y}
			surface.create_entity({name = ore, position = p, amount = 1000 + distance_to_center * 2})
		end
	end	
end

local function update_rendering(cell, position)
	if cell[2] then
		rendering.destroy(cell[2])
	end
	
	local color
	if number_colors[cell[1]] then
		color = number_colors[cell[1]]
	else
		color = {125, 125, 125}
	end
	
	local text
	if cell[1] == 11 then
		text = "X" 
	else
		text = cell[1]
	end
	
	cell[2] = rendering.draw_text{text=text, surface=game.surfaces[1], target={position.x + 0.55, position.y - 0.25}, color=color, scale=3, font="scenario-message-dialog", draw_on_ground=true, scale_with_zoom=false, only_in_alt_mode=false}
end

local function clear_cell(position)
	local surface = game.surfaces[1]
	
	local noise = Get_noise("smol_areas", position, surface.map_gen_settings.seed)
	local noise_2 = Get_noise("smol_areas", position, surface.map_gen_settings.seed + 50000)
	if noise_2 > 0.50 or math.abs(noise) > 0.14 or surface.count_entities_filtered({type = {"resource", "container"}, area = {{position.x + 0.25, position.y + 0.25}, {position.x + 1.75, position.y + 1.75}}}) > 0 then
		if noise < 0 then
			tile_name = "sand-" .. math.floor((noise * 10) % 3 + 1)
		else
			tile_name = "grass-" .. math.floor((noise * 10) % 3 + 1)
		end		
	else
		tile_name = "water-shallow"
	end
	
	for x = 0, 1, 1 do
		for y = 0, 1, 1 do
			local p = {x = position.x + x, y = position.y + y}
			surface.set_tiles({{name = tile_name, position = p}}, true)
			if math.random(1, 24) == 1 and tile_name == "water-shallow" then
				surface.create_entity({name = "fish", position = p})
			end
		end
	end	
	local key = position_to_string(position)
	local cell = minesweeper.cells[key]
	if cell and cell[2] then rendering.destroy(cell[2]) end
	minesweeper.cells[key] = nil
end

local function update_cell(position)
	local tile = game.surfaces.nauvis.get_tile(position)	
	if tile.name ~= "nuclear-ground" and tile.hidden_tile ~= "nuclear-ground" then return end

	local key = position_to_string(position)
	if not minesweeper.cells[key] then
		minesweeper.cells[key] = {-1}
	end
	
	if minesweeper.cells[key][1] > 9 then return end

	local adjacent_mine_count = 0
	for _, vector in pairs(cell_update_vectors) do
		local p = {x = position.x + vector[1], y = position.y + vector[2]}
		local key = position_to_string(p)
		if minesweeper.cells[key] then
			if minesweeper.cells[key][1] > 9 then		
				adjacent_mine_count = adjacent_mine_count + 1
			end
		end
	end
	
	local cell = minesweeper.cells[key]
	cell[1] = adjacent_mine_count
	update_rendering(cell, position)
	
	if adjacent_mine_count == 0 then
		table.insert(minesweeper.zero_queue, position)
	end
end

local function visit_cell(position)
	local key = position_to_string(position)
	local cell = minesweeper.cells[key]
	local score_change = 0
	if cell then
		if cell[1] == 10 then
			kaboom(position)
			score_change = -8
			cell[1] = -1
			for _, vector in pairs(cell_update_vectors) do
				local p = {x = position.x + vector[1], y = position.y + vector[2]}
				local key = position_to_string(p)
				if minesweeper.cells[key] then
					update_cell(p)
				end
			end
		end	
	end

	update_cell(position)
	
	local cell = minesweeper.cells[key]
	if not cell or cell[1] == 0 then
		for _, vector in pairs(cell_update_vectors) do
			local p = {x = position.x + vector[1], y = position.y + vector[2]}
			update_cell(p)
		end		
		clear_cell(position)
	end
	
	return score_change
end

local function get_solving_vectors(position)
	local distance_to_center = math.sqrt(position.x ^ 2 + position.y ^ 2)
	local key = math.floor(distance_to_center * 0.005) + 1
	if key > size_of_solving_vector_tables then key = size_of_solving_vector_tables end
	local solving_vectors = solving_vector_tables[key]
	return solving_vectors
end

local function are_mines_marked_around_target(position)
	local marked_positions = {}
	for _, vector in pairs(get_solving_vectors(position)) do
		local p = {x = position.x + vector[1], y = position.y + vector[2]}
		local key = position_to_string(p)
		local cell = minesweeper.cells[key]
		if cell then
			if cell[1] == 10 then return end
			if cell[1] == 11 then table.insert(marked_positions, p) end
		end
	end
	return marked_positions
end

local function solve_attempt(position)
	for _, vector in pairs(get_solving_vectors(position)) do
		local p = {x = position.x + vector[1], y = position.y + vector[2]}
		local key = position_to_string(p)
		local cell = minesweeper.cells[key]
		if cell and cell[1] > 10 then
			local marked_positions = are_mines_marked_around_target(p)
			if marked_positions then
				for _, p in pairs(marked_positions) do
					minesweeper.cells[position_to_string(p)][1] = -1
					visit_cell(p)
					disarm_reward(p)
				end
			end
		end
	end
end

local function mark_mine(entity)
	local position = position_to_cell_position(entity.position)
	local key = position_to_string(position)
	local cell = minesweeper.cells[key]
	local score_change = 0
	
	--Success
	if cell and cell[1] > 9 then
		if cell[1] == 10 then score_change = 1 end	
		
		entity.surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "Mine marked.",
			color = {r=0.98, g=0.66, b=0.22}
		})
				
		--	
		cell[1] = 11
		update_rendering(cell, position)
		
		entity.destroy()
		game.surfaces.nauvis.spill_item_stack({position.x + 1, position.y + 1}, {name = 'stone-furnace', count = 1}, true)

		solve_attempt(position)
	
		return score_change
	end
	
	--Trigger all adjecant mines when missplacing a disarming furnace.
	for _, vector in pairs(cell_update_vectors) do
		local p = {x = position.x + vector[1], y = position.y + vector[2]}
		local key = position_to_string(p)
		if minesweeper.cells[key] and minesweeper.cells[key][1] == 10 then
			kaboom(p)
			score_change = score_change - 8
			minesweeper.cells[key][1] = -1
			solve_attempt(p)
		end
	end
	for _, vector in pairs(cell_update_vectors) do
		local p = {x = position.x + vector[1], y = position.y + vector[2]}
		local key = position_to_string(p)
		if minesweeper.cells[key] then
			visit_cell(p)
		end
	end
	return score_change
end

local function get_adjecant_mine_count(position)
	local count = 0
	for _, vector in pairs(cell_adjecant_vectors) do
		local p = {x = position.x + vector[1], y = position.y + vector[2]}
		local key = position_to_string(p)
		local cell = minesweeper.cells[key]
		if cell and cell[1] == 10 then count = count + 1 end
	end
	return count
end

local function add_mines_to_chunk(left_top)
	local distance_to_center = math.sqrt((left_top.x + 16) ^ 2 + (left_top.y + 16) ^ 2)
	local base_mine_count = 40
	local max_mine_count = 128
	local mine_count = distance_to_center * 0.043 + base_mine_count
	if mine_count > max_mine_count then mine_count = max_mine_count end

	local shuffle_index = {}
	for i = 1, size_of_chunk_divide_vectors, 1 do table.insert(shuffle_index, i) end
	table.shuffle_table(shuffle_index)
	
	-- place shuffled mines
	for i = 1, mine_count, 1 do		
		local vector = chunk_divide_vectors[shuffle_index[i]]
		local position = {x = left_top.x + vector[1], y = left_top.y + vector[2]}		
		local key = position_to_string(position)
		minesweeper.cells[key] = {10}
		minesweeper.active_mines = minesweeper.active_mines + 1		
	end
	
	-- remove mines that would form a 3x3 block
	for _, chunk_vector in pairs(chunk_vectors) do
		local left_top_2 = {x = left_top.x + chunk_vector[1], y = left_top.y + chunk_vector[2]}
		
		for _, vector in pairs(chunk_divide_vectors) do
			local position = {x = left_top_2.x + vector[1], y = left_top_2.y + vector[2]}
			local key = position_to_string(position)
			local cell = minesweeper.cells[key]
			if cell and cell[1] == 10 then		
				if get_adjecant_mine_count(position) == 8 then
					--if cell[2] then rendering.destroy(cell[2]) end
					minesweeper.cells[key] = nil 
				end			
			end
		end
		--[[
		for _, vector in pairs(chunk_divide_vectors) do
			local position = {x = left_top_2.x + vector[1], y = left_top_2.y + vector[2]}
			local key = position_to_string(position)
			local cell = minesweeper.cells[key]
			if cell then update_rendering(cell, position) end
		end
		]]
	end
end

local function on_chunk_generated(event)
	local left_top = event.area.left_top
	if event.surface.index ~= 1 then return end
	
	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			table.insert(tiles, {name = "nuclear-ground", position = {x = left_top.x + x, y = left_top.y + y}})
		end
	end
	event.surface.set_tiles(tiles, true)
	
	--surface.clear() will cause to trigger on_chunk_generated twice
	local key = position_to_string(left_top)
	if minesweeper.chunks[key] then return end
	minesweeper.chunks[key] = true
	
	add_mines_to_chunk(left_top)
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	local tile = game.surfaces.nauvis.get_tile(player.position)	
	if tile.name ~= "nuclear-ground" and tile.hidden_tile ~= "nuclear-ground" then return end
	local cell_position = position_to_cell_position(player.position)
	local score_change = visit_cell(cell_position)
	if score_change < 0 then solve_attempt(cell_position) end
	Map_score.set_score(player, Map_score.get_score(player) + score_change)
end

local function deny_building(event)
	local entity = event.created_entity
	if not entity.valid then return end
	if entity.name == "entity-ghost" then return end
	local tile = entity.surface.get_tile(entity.position)
	if tile.name == "nuclear-ground" or tile.hidden_tile == "nuclear-ground" then
		if event.player_index then
			local player = game.players[event.player_index]
			if entity.position.x % 2 == 1 and entity.position.y % 2 == 1 and entity.name == "stone-furnace" then
				local score_change = mark_mine(entity)
				Map_score.set_score(player, Map_score.get_score(player) + score_change)
				return
			end	
			player.insert({name = entity.name, count = 1})
		else
			local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
			inventory.insert({name = entity.name, count = 1})
		end
		entity.destroy()
	end
end

local function on_built_entity(event)
	deny_building(event)
end

local function on_robot_built_entity(event)
	deny_building(event)
end

local function on_player_created(event)
	local player = game.players[event.player_index]
	player.insert({name = "stone-furnace", count = 1})
end

local function on_player_respawned(event)
	local player = game.players[event.player_index]
	player.insert({name = "stone-furnace", count = 1})
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.force.index ~= 2 then return end
	local force = event.force
	if not force then return end	
	if force.name ~= "minesweeper" then return end
	local revived_entity = entity.clone({position = entity.position})
	revived_entity.health = entity.prototype.max_health
	entity.destroy()
end

local function on_nth_tick()
	local position = minesweeper.zero_queue[1]
	if not position then return end
	local key = position_to_string(position)
	local cell = minesweeper.cells[key]
	if cell then visit_cell(position) end
	table.remove(minesweeper.zero_queue, 1)
end

local function on_init()
	game.create_force("minesweeper")

	global.custom_highscore.description = "Minesweep rank:"

	local surface = game.surfaces[1]
	local mgs = surface.map_gen_settings
	mgs.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}
	mgs.autoplace_controls = {
		["coal"] = {frequency = 0, size = 0, richness = 0},
		["stone"] = {frequency = 0, size = 0, richness = 0},
		["copper-ore"] = {frequency = 0, size = 0, richness = 0},
		["iron-ore"] = {frequency = 0, size = 0, richness = 0},
		["uranium-ore"] = {frequency = 0, size = 0, richness = 0},
		["crude-oil"] = {frequency = 0, size = 0, richness = 0},
		["trees"] = {frequency = 4, size = 0.5, richness = 0.1},
	}
	surface.map_gen_settings = mgs
	surface.clear(true)	

	minesweeper.chunks = {}
	minesweeper.cells = {}
	minesweeper.zero_queue = {}
	minesweeper.player_data = {}
	minesweeper.active_mines = 0
	minesweeper.disarmed_mines = 0
	minesweeper.triggered_mines = 0
		
	local T = Map.Pop_info()
	T.main_caption = "Minesweeper"
	T.sub_caption =  ""
	T.text = table.concat({
		"Mechanical lifeforms once dominated this world.\n",
		"They have left long ago, leaving an inhabitable wasteland.\n",
		"It also seems riddled with buried explosives.\n\n",
		
		"Mark mines with your stone furnace.\n",
		"Marked mines are save to walk on.\n",
		"When enough mines in an area are marked,\n",
		"they will disarm and yield rewards!\n",
		"Faulty marking may trigger surrounding mines!!\n\n",
		
		"As you move away from spawn,\n",
		"mine density and radius required to disarm will increase.\n",
		"Crates will contain more loot and ore will have higher yield.\n",		
	})
	T.main_caption_color = {r = 255, g = 125, b = 55}
	T.sub_caption_color = {r = 0, g = 250, b = 150}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(3, on_nth_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_player_respawned, on_player_respawned)