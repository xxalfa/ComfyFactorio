-- 1 to 9 = adjecant mines
-- 10 = mine

require 'modules.satellite_score'

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
}

local chunk_divide_vectors = {}
for x = 0, 30, 2 do
	for y = 0, 30, 2 do
		table.insert(chunk_divide_vectors, {x,y})
	end
end
local size_of_chunk_divide_vectors = #chunk_divide_vectors

local cell_update_vectors = {}
for x = -2, 2, 2 do
	for y = -2, 2, 2 do
		table.insert(cell_update_vectors, {x,y})
	end
end

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
	
	if math.random(1, 4) ~= 1 then return end
	
	if math.random(1, 8) == 1 then
		local blacklist = LootRaffle.get_tech_blacklist(0.05 + distance_to_center * 0.0002)
		local item_stacks = LootRaffle.roll(math.random(16, 48) + math.floor(distance_to_center * 0.1), 16, blacklist)
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
	
	cell[2] = rendering.draw_text{text=cell[1], surface=game.surfaces[1], target={position.x + 0.55, position.y - 0.25}, color=color, scale=3, font="scenario-message-dialog", draw_on_ground=true, scale_with_zoom=false, only_in_alt_mode=false}
end

local function clear_cell(position)
	local surface = game.surfaces[1]
	
	local noise = Get_noise("smol_areas", position, surface.map_gen_settings.seed)
	if math.abs(noise) > 0.15 or surface.count_entities_filtered({type = {"resource", "container"}, area = {{position.x + 0.25, position.y + 0.25}, {position.x + 1.75, position.y + 1.75}}}) > 0 then
		tile_name = "grass-" .. math.floor((noise * 10) % 3 + 1)
	else
		tile_name = "water-shallow"
	end
	
	for x = 0, 1, 1 do
		for y = 0, 1, 1 do
			local p = {x = position.x + x, y = position.y + y}
			surface.set_tiles({{name = tile_name, position = p}}, true)
		end
	end	
	local key = position_to_string(position)
	local cell = minesweeper.cells[key]
	if cell[2] then rendering.destroy(cell[2]) end
	minesweeper.cells[key] = nil
end

local function update_cell(position)
	local tile = game.surfaces.nauvis.get_tile(position)	
	if tile.name ~= "nuclear-ground" and tile.hidden_tile ~= "nuclear-ground" then return end

	local key = position_to_string(position)
	if not minesweeper.cells[key] then
		minesweeper.cells[key] = {-1}
	end
	
	if minesweeper.cells[key][1] == 10 then return end

	local adjacent_mine_count = 0
	for _, vector in pairs(cell_update_vectors) do
		local p = {x = position.x + vector[1], y = position.y + vector[2]}
		local key = position_to_string(p)
		if minesweeper.cells[key] then
			if minesweeper.cells[key][1] == 10 then		
				adjacent_mine_count = adjacent_mine_count + 1
			end
		end
	end
	
	local cell = minesweeper.cells[key]
	cell[1] = adjacent_mine_count
	update_rendering(cell, position)
end

local function visit_cell(position)
	local key = position_to_string(position)
	local cell = minesweeper.cells[key]
	if cell then
		if cell[1] == 10 then
			kaboom(position)
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
end

local function disarm_mine(entity)
	local position = position_to_cell_position(entity.position)
	local key = position_to_string(position)
	local cell = minesweeper.cells[key]
	
	--Success
	if cell and cell[1] == 10 then
		entity.surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "Mine disarmed!",
			color = {r=0.98, g=0.66, b=0.22}
		})
		disarm_reward(position)
		minesweeper.disarmed_mines = minesweeper.disarmed_mines + 1
		cell[1] = -1
		visit_cell(position)
		for _, vector in pairs(cell_update_vectors) do
			local p = {x = position.x + vector[1], y = position.y + vector[2]}
			local key = position_to_string(p)
			if minesweeper.cells[key] then	update_cell(p) end
		end		
		entity.destroy()
		game.surfaces.nauvis.spill_item_stack({position.x + 1, position.y + 1}, {name = 'stone-furnace', count = 1}, true)
		return
	end
	
	--Trigger all adjecant mines when missplacing a disarming furnace.
	for _, vector in pairs(cell_update_vectors) do
		local p = {x = position.x + vector[1], y = position.y + vector[2]}
		local key = position_to_string(p)
		if minesweeper.cells[key] and minesweeper.cells[key][1] == 10 then
			kaboom(p)
			minesweeper.cells[key][1] = -1
		end
	end
	for _, vector in pairs(cell_update_vectors) do
		local p = {x = position.x + vector[1], y = position.y + vector[2]}
		local key = position_to_string(p)
		if minesweeper.cells[key] then
			visit_cell(p)
		end
	end
end

local function add_mines_to_chunk(left_top)	
	local mine_count = math.random(minesweeper.average_mines_per_chunk * 0.5, minesweeper.average_mines_per_chunk * 1.5)
	local shuffle_index = {}
	for i = 1, size_of_chunk_divide_vectors, 1 do table.insert(shuffle_index, i) end
	table.shuffle_table(shuffle_index)
	
	for i = 1, mine_count, 1 do
		local key = shuffle_index[i]
		local vector = chunk_divide_vectors[key]
		local p = {x = left_top.x + vector[1], y = left_top.y + vector[2]}		
		minesweeper.cells[position_to_string(p)] = {10}
		minesweeper.active_mines = minesweeper.active_mines + 1
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
	
	add_mines_to_chunk(left_top)
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	local tile = game.surfaces.nauvis.get_tile(player.position)	
	if tile.name ~= "nuclear-ground" and tile.hidden_tile ~= "nuclear-ground" then return end	
	visit_cell(position_to_cell_position(player.position))	
end

local function deny_building(event)
	local entity = event.created_entity
	if not entity.valid then return end
	if entity.name == "entity-ghost" then return end
	local tile = entity.surface.get_tile(entity.position)
	if tile.name == "nuclear-ground" or tile.hidden_tile == "nuclear-ground" then
		if event.player_index then
			if entity.position.x % 2 == 1 and entity.position.y % 2 == 1 and entity.name == "stone-furnace" then
				disarm_mine(entity)
				return
			end	
			game.players[event.player_index].insert({name = entity.name, count = 1})
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

local function on_init()
	game.create_force("minesweeper")

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

	minesweeper.cells = {}
	minesweeper.player_data = {}
	minesweeper.average_mines_per_chunk = 48
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
		
		"Disarm mines with your stone furnace.\n",
		"Successful disarms will yield rewards!\n\n",
		
		"Faulty disarming may trigger surrounding mines!!\n",
	})
	T.main_caption_color = {r = 255, g = 125, b = 55}
	T.sub_caption_color = {r = 0, g = 250, b = 150}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_player_respawned, on_player_respawned)