local math_random = math.random
local nom_msg = {"munch", "munch", "yum"}

local Public = {}

local function feed_floaty_text(unit)
	unit.surface.create_entity({name = "flying-text", position = unit.position, text = nom_msg[math_random(1, #nom_msg)], color = {math_random(50, 100), 0, 255}})
end

local function floaty_hearts(entity, c)
	local position = {x = entity.position.x - 0.75, y = entity.position.y - 1}
	local b = 1.35
	for a = 1, c, 1 do
		local p = {(position.x + 0.4) + (b * -1 + math_random(0, b * 20) * 0.1), position.y + (b * -1 + math_random(0, b * 20) * 0.1)}			
		entity.surface.create_entity({name = "flying-text", position = p, text = "♥", color = {math_random(150, 255), 0, 255}})						
	end
end

local function tame_unit_effects(player, entity)
	floaty_hearts(entity, 7)
	
	rendering.draw_text{
		text = "~" .. player.name .. "'s pet~",
		surface = player.surface,
		target = entity,
		target_offset = {0, -2.6},
		color = {
			r = player.color.r * 0.6 + 0.25,
			g = player.color.g * 0.6 + 0.25,
			b = player.color.b * 0.6 + 0.25,
			a = 1
		},
		scale = 1.05,
		font = "default-large-semibold",
		alignment = "center",
		scale_with_zoom = false
	}
end

local function find_unit(player, entity)
	local units = player.surface.find_entities_filtered({type = "unit", area = {{entity.position.x - 1, entity.position.y - 1},{entity.position.x + 1, entity.position.y + 1}}, limit = 1})
	return units[1]
end

local function feed_pet(unit)
	if unit.prototype.max_health == unit.health then return end
	unit.health = unit.health + 8 + math.floor(unit.prototype.max_health * 0.05)
	feed_floaty_text(unit)
	floaty_hearts(unit, math_random(1,2))
	return true
end

function Public.biter_pets_tame_unit(player, unit, forced)
	if global.biter_pets[player.index] then return false end
	if not forced then
		if math_random(1, math.floor(unit.prototype.max_health * 0.01) + 1) ~= 1 then
			feed_floaty_text(unit)
			return true
		end
	end
	if unit.force.index == player.force.index then return false end
	unit.ai_settings.allow_destroy_when_commands_fail = false
	unit.ai_settings.allow_try_return_to_spawner = false
	unit.force = player.force
	unit.set_command({type = defines.command.wander, distraction = defines.distraction.by_enemy})	
	global.biter_pets[player.index] = {last_command = 0, entity = unit}
	tame_unit_effects(player, unit)
	return true
end

local function command_unit(entity, player)
	if (player.position.x - entity.position.x) ^ 2 + (player.position.y - entity.position.y) ^ 2 < 256 then
		entity.set_command({type = defines.command.wander, distraction = defines.distraction.by_enemy})
	else
		entity.set_command({type = defines.command.go_to_location, destination_entity = player.character, radius = 4, distraction = defines.distraction.by_damage})
	end
end

local function on_player_changed_position(event)
	if math_random(1, 100) ~= 1 then return end
	local player = game.players[event.player_index]
	if not global.biter_pets[player.index] then return end	
	if not global.biter_pets[player.index].entity then global.biter_pets[player.index] = nil return end
	if not global.biter_pets[player.index].entity.valid then global.biter_pets[player.index] = nil return end
	if not player.character then return end
	if global.biter_pets[player.index].last_command + 600 > game.tick then return end
	global.biter_pets[player.index].last_command = game.tick
	command_unit(global.biter_pets[player.index].entity, player)	
end

local function on_player_dropped_item(event)
	local player = game.players[event.player_index]
	if event.entity.stack.name ~= "raw-fish" then return end
	local unit = find_unit(player, event.entity)
	if not unit then return end
	if Public.biter_pets_tame_unit(player, unit, false) then event.entity.destroy() return end
	if unit.force.index == player.force.index then feed_pet(unit) end	
end

local function on_init(event)
	global.biter_pets = {}
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
event.add(defines.events.on_player_changed_position, on_player_changed_position)

return Public