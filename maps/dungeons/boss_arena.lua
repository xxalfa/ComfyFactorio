
local RPG_F = require "modules.rpg.functions"
local RPG_T = require "modules.rpg.table"
--local RPG_S = require "modules.rpg.settings"
local BiterHealthBooster = require "modules.biter_health_booster"
local Alert = require 'utils.alert'
local math_floor = math.floor
local math_min = math.min
local math_random = math.random

local arena_areas = {
  [1] = {area = {{54,54}, {74,74}}, center = {64,64}, player = {69,64}, boss = {59,64}},
  [2] = {area = {{-74,54}, {-54, 74}}, center = {-64,64}, player = {-59,64}, boss = {-69,64}},
  [3] = {area = {{54,-74}, {74,-54}}, center = {64,-64}, player = {69,-64}, boss = {59,-64}},
  [4] = {area = {{-74, -74}, {-54,-54}}, center = {-64,-64}, player = {-59,-64}, boss = {-69,-64}}
}
local function create_arena(arena)
  local surface = game.surfaces["nauvis"]
  local area = arena_areas[arena].area
  surface.request_to_generate_chunks(arena_areas[arena].center, 2)
	surface.force_generate_chunk_requests()
  local tiles = {}
  local entities = {}
  for x = area[1][1], area[2][1], 1 do
    for y = area[1][2], area[2][2], 1 do
      tiles[#tiles + 1] = {name = "landfill", position = {x = x, y = y}}
      if x == area[1][1] or x == area[2][1] or y == area[1][2] or y == area[2][2] then
        entities[#entities + 1] = {name = "stone-wall", force = "neutral", position = {x = x, y = y}}
      end
    end
  end
  surface.set_tiles(tiles)
  for _,entity in pairs(entities) do
    local e = surface.create_entity(entity)
    e.destructible = false
    e.minable = false
  end
  global.arena.created[arena] = true
end

local function reset_arena(arena)
	global.arena.timer[arena] = -100
	global.arena.active_player[arena] = nil
end

local function wipedown_arena(arena)
	local player = global.arena.active_player[arena]
	local surface = game.surfaces["nauvis"]
	local area = arena_areas[arena].area
	local acids = surface.find_entities_filtered{area = {{area[1][1] - 5, area[1][2] - 5}, {area[2][1] + 5,area[2][2] + 5}}, type = "fire"}
	for _,acid in pairs(acids) do
		acid.destroy()
	end
	local robots = surface.find_entities_filtered{area = {{area[1][1] - 15, area[1][2] - 15}, {area[2][1] + 15,area[2][2] + 15}}, force = {"arena" .. arena}}
	for _,robot in pairs(robots) do
		robot.destroy()
	end
end

local function calculate_xp(level)
  local xp_gains = {
    ['behemoth-biter'] = 16,
    ['behemoth-spitter'] = 16,
    ['big-biter'] = 8,
    ['big-spitter'] = 8,
    ['medium-biter'] = 4,
    ['medium-spitter'] = 4,
    ['small-biter'] = 1,
    ['small-spitter'] = 1
  }
  local biter_names = {{"small-biter", "small-spitter"}, {"medium-biter", "medium-spitter"}, {"big-biter", "big-spitter"}, {"behemoth-biter", "behemoth-spitter"}}
  local biter = biter_names[math_min(1 + math_floor(level / 20), 4)][1 + level % 2]
  return xp_gains[biter] * 8 * (2 + 0.2 * level - 1 * math_floor(level / 20))
end

local function calculate_hp(level)
  return 2 + 0.2 * level - 1 * math_floor(level / 20)
end

local function calculate_dmg(level)
  if level >= 80 then level = level * 2 end
  return 1 + 0.1 * level - 1 * math_floor(level / 20)
end

local function draw_boss_gui()
	for _, player in pairs(game.connected_players) do
		if not player.gui.top.boss_arena then
      local level = global.arena.bosses[player.index] or 0
      local tooltip = {"dungeons_tiered.boss_arena", level, calculate_hp(level)*100, calculate_dmg(level)*100, math_floor(4 + level + calculate_xp(level))}
			player.gui.top.add({type = "sprite-button", name = "boss_arena", sprite = "entity/behemoth-biter", tooltip = tooltip})
		end
	end
end

local function update_boss_gui(player)
  if not player.gui.top.boss_arena then draw_boss_gui() end
  local level = global.arena.bosses[player.index] or 0
  local tooltip = {"dungeons_tiered.boss_arena", level, calculate_hp(level)*100, calculate_dmg(level)*100, math_floor(4 + level + calculate_xp(level))}
  player.gui.top.boss_arena.tooltip = tooltip
end

local function arena_occupied(arena)
  if global.arena.active_player[arena] then return true end
  if global.arena.active_boss[arena] then return true end
  return false
end

local function spawn_boss(arena, biter, level)
  local surface = game.surfaces["nauvis"]
  local force = game.forces[global.arena.enemies[arena].index]
  global.biter_health_boost_forces[force.index] = calculate_hp(level)
  force.set_ammo_damage_modifier("melee", calculate_dmg(level))
  force.set_ammo_damage_modifier("biological", calculate_dmg(level))
  local pos = {x = arena_areas[arena].center[1],y = arena_areas[arena].center[2]}
  pos.x = pos.x - 6 + math_random(0,12)
  pos.y = pos.y - 6 + math_random(0,12)
  local boss = surface.create_entity({name = biter, position = pos, force = force})
  boss.ai_settings.allow_try_return_to_spawner = false
  global.arena.active_boss[arena] = boss
  rendering.draw_text{
		text = "Boss lvl " .. level,
		surface = surface,
		target = boss,
		target_offset = {0, -2.5},
		color = {r = 1, g = 0, b = 0},
		scale = 1.40,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
  BiterHealthBooster.add_boss_unit(boss, global.biter_health_boost_forces[force.index] * 8, 0.25)
end

local function hide_rpg(player, show)
  local rpg_button = RPG_T.draw_main_frame_name
  local rpg_frame = RPG_T.main_frame_name
  local rpg_settings = RPG_T.settings_frame_name

  local rpg_b = player.gui.top[rpg_button]
  local rpg_f = player.gui.screen[rpg_frame]
  local rpg_s = player.gui.screen[rpg_settings]

  if show then
    if rpg_b then rpg_b.visible = true end
  else
    if rpg_b then rpg_b.visible = false end
    if rpg_f then rpg_f.destroy() end
    if rpg_s then rpg_s.destroy() end
  end
end

local function teleport_player_out(arena, player)
  local surface = global.arena.previous_position[arena].surface
  local position = global.arena.previous_position[arena].position
  local rpg = RPG_T.get("rpg_t")
  rpg[player.index].one_punch = true
  hide_rpg(player, true)
  player.teleport(surface.find_non_colliding_position("character", position, 20, 0.5), surface)
  global.arena.previous_position[arena].position = nil
  global.arena.previous_position[arena].surface = nil
  reset_arena(arena)
  local group = game.permissions.get_group('Default')
  group.add_player(player)
end

local function teleport_player_in(arena, player)
  local surface = game.surfaces["nauvis"]
  global.arena.previous_position[arena].position = player.position
  global.arena.previous_position[arena].surface = player.surface
  global.arena.timer[arena] = game.tick
  local rpg = RPG_T.get("rpg_t")
  rpg[player.index].one_punch = false
  hide_rpg(player, false)
  
  local pos = {x = arena_areas[arena].center[1],y = arena_areas[arena].center[2]}
  pos.x = pos.x - 6 + math_random(0,12)
  pos.y = pos.y - 6 + math_random(0,12)
  
  player.teleport(surface.find_non_colliding_position("character", pos, 20, 0.5), surface)
  global.arena.active_player[arena] = player
  local group = game.permissions.get_group('Arena')
  group.add_player(player)
end

local function player_died(arena, player)
	wipedown_arena(arena)
	global.arena.active_player[arena] = nil
	global.arena.active_boss[arena].destroy()
	global.arena.active_boss[arena] = nil
	global.arena.timer[arena] = -100
  
	teleport_player_out(arena, player)
	player.character.health = 5
	
	if not global.arena.won[arena] then --incase of death after victory
		local level = global.arena.bosses[player.index]
		--game.print({"dungeons_tiered.player_lost", player.name, global.arena.bosses[player.index]})
		if level % 10 == 0 and level > 0 then
			Alert.alert_all_players(8, {"dungeons_tiered.player_lost", player.name, global.arena.bosses[player.index]}, {r=0.8,g=0.2,b=0},"entity/behemoth-biter", 0.7)
		else
			Alert.alert_player(player, 8, {"dungeons_tiered.player_lost", player.name, global.arena.bosses[player.index]}, {r=0.8,g=0.2,b=0},"entity/behemoth-biter", 0.7)
		end
	end
end

local function boss_died(arena)
  global.arena.active_boss[arena] = nil
  local player = global.arena.active_player[arena]
  local level = global.arena.bosses[player.index]
  wipedown_arena(arena)
  global.arena.won[arena] = true
  global.arena.timer[arena] = game.tick - 30
  --teleport_player_out(arena, player)
  RPG_F.gain_xp(player, 4 + level, true)
  if level % 10 == 0 and level > 0 then
    Alert.alert_all_players(8, {"dungeons_tiered.player_won", player.name, global.arena.bosses[player.index]}, {r=0.8,g=0.2,b=0},"entity/behemoth-biter", 0.7)
  else
    Alert.alert_player(player, 8, {"dungeons_tiered.player_won", player.name, global.arena.bosses[player.index]}, {r=0.8,g=0.2,b=0},"entity/behemoth-biter", 0.7)
  end
  --game.print({"dungeons_tiered.player_won", player.name, global.arena.bosses[player.index]})
  global.arena.bosses[player.index] = global.arena.bosses[player.index] + 1
  --global.arena.active_player[arena] = nil
  --global.arena.timer[arena] = -100
  update_boss_gui(player)
end

local function choose_arena()
  for i = 1, 4, 1 do
    if not global.arena.created[i] then create_arena(i) end
    if not arena_occupied(i) then return i end
  end
  return nil
end

local function enter_arena(player)
  if not player.character then return end
  if player.surface.name == "nauvis" then return end
  local chosen_arena = choose_arena()
  if not chosen_arena then
    Alert.alert_player_warning(player, 8, {"dungeons_tiered.arena_occupied"})
    -- player.print({"dungeons_tiered.arena_occupied"})
    return
  end
  local rpg_t = RPG_T.get("rpg_t")
  if rpg_t[player.index].level < 5 then
    Alert.alert_player_warning(player, 8, {"dungeons_tiered.arena_level_needed"})
    return
  end
  if #player.character.following_robots > 0 then
    Alert.alert_player_warning(player, 8, {"dungeons_tiered.robots_following"})
    return
  end

  local level = global.arena.bosses[player.index]
  if level > 100 then
    Alert.alert_player_warning(player, 8, {"dungeons_tiered.arena_level_max"})
    return
  end
  --local biter_names = {{"small-biter", "small-spitter"}, {"medium-biter", "medium-spitter"}, {"big-biter", "big-spitter"}, {"behemoth-biter", "behemoth-spitter"}}
  --local biter = biter_names[math_min(1 + math_floor(level / 20), 4)][1 + level % 2]
  --spawn_boss(chosen_arena, biter, level)
  global.arena.won[chosen_arena] = false
  teleport_player_in(chosen_arena, player)
end

local function on_player_joined_game(event)
	draw_boss_gui()
  if not global.arena.bosses[event.player_index] then global.arena.bosses[event.player_index] = 0 end
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.element.player_index]
	if event.element.name == "boss_arena" then
		enter_arena(player)
		return
	end
end

local function on_pre_player_died(event)
  local player = game.players[event.player_index]
  if not player.valid then return end
  for i = 1, 4, 1 do
    if player == global.arena.active_player[i] then
      player_died(i, player)
    end
  end
end

local function on_pre_player_left_game(event)
  local player = game.players[event.player_index]
  if not player.valid then return end
  for i = 1, 4, 1 do
    if player == global.arena.active_player[i] then
      player_died(i, player)
    end
  end
end

local function on_entity_died(event)
  local entity = event.entity
  if not entity.valid then return end
  for i = 1, 4, 1 do
    if entity == global.arena.active_boss[i] then
      boss_died(i)
    end
  end
end

local function shoot(surface, biter, player)
  surface.create_entity({name = "destroyer-capsule", position = biter.position, target = player.character, source = biter, speed = 1, force = biter.force})
end

local function slow(surface, biter, player)
  surface.create_entity({name = "slowdown-capsule", position = biter.position, target = player.character, source = biter, speed = 1, max_range = 100})
end

local function boss_attacks(i)
  if not global.arena.active_boss[i] then return end
  if not global.arena.active_player[i] then return end
  local biter = global.arena.active_boss[i]
  local player = global.arena.active_player[i]
  local surface = game.surfaces["nauvis"]
  --if not biter.valid or not player.valid or not player.character or not player.character.valid then return end
  if not biter or not player or not player.character then return end
  if global.arena.bosses[player.index] >= 80 then
    slow(surface, biter, player)
    --shoot(surface, biter, player)
  end
  if global.arena.timer[i] + 3600 < game.tick and game.tick %120 == 0 then slow(surface, biter, player) end
  if global.arena.timer[i] + 7200 < game.tick and game.tick %120 == 0 then shoot(surface, biter, player) end
  if biter.name == "small-spitter" then
    surface.create_entity({name = "acid-stream-spitter-small", position = biter.position, target = player.character, source = biter})
    surface.create_entity({name = "acid-stream-spitter-small", position = biter.position, target = player.character, source = biter})
  elseif biter.name == "medium-spitter" then
    surface.create_entity({name = "acid-stream-spitter-medium", position = biter.position, target = player.character, source = biter})
    surface.create_entity({name = "acid-stream-spitter-medium", position = biter.position, target = player.character, source = biter})
  elseif biter.name == "big-spitter" then
    surface.create_entity({name = "acid-stream-spitter-big", position = biter.position, target = player.character, source = biter})
    surface.create_entity({name = "acid-stream-spitter-big", position = biter.position, target = player.character, source = biter})
  elseif biter.name == "behemoth-spitter" then
    surface.create_entity({name = "acid-stream-spitter-behemoth", position = biter.position, target = player.character, source = biter})
    surface.create_entity({name = "acid-stream-spitter-behemoth", position = biter.position, target = player.character, source = biter})
  end
end

local function tick()
  for i = 1, 4, 1 do
    boss_attacks(i)
  end
end

local function arena_ticker()
  for i = 1, 4, 1 do
	if global.arena.timer[i] == game.tick - 90 then
		--game.print("I did a delay")

		local player = global.arena.active_player[i]
		if player.valid then
			if global.arena.won[i] then
				--game.print("You won, now get lost")
				teleport_player_out(i, player)
			else
				local level = global.arena.bosses[player.index]

				local biter_names = {{"small-biter", "small-spitter"}, {"medium-biter", "medium-spitter"}, {"big-biter", "big-spitter"}, {"behemoth-biter", "behemoth-spitter"}}
				local biter = biter_names[math_min(1 + math_floor(level / 20), 4)][1 + level % 2]
				spawn_boss(i, biter, level)
			end
		end

		
	end
  end
end

local function on_init()
  global.arena = {}
	global.arena.bosses = {}
  global.arena.created = {[1] = false, [2] = false, [3] = false, [4] = false}
  global.arena.active_player = {[1] = nil, [2] = nil, [3] = nil, [4] = nil}
  global.arena.active_boss = {[1] = nil, [2] = nil, [3] = nil, [4] = nil}
  global.arena.enemies = {[1] = nil, [2] = nil, [3] = nil, [4] = nil}
  global.arena.timer = {[1] = -100, [2] = -100, [3] = -100, [4] = -100}
  global.arena.won = {[1] = false, [2] = false, [3] = false, [4] = false}
  global.arena.previous_position = {[1] = {position = nil, surface = nil}, [2] = {position = nil, surface = nil}, [3] = {position = nil, surface = nil}, [4] = {position = nil, surface = nil}}
  local arena = game.permissions.create_group('Arena')
  arena.set_allows_action(defines.input_action.cancel_craft, false)
  arena.set_allows_action(defines.input_action.edit_permission_group, false)
  arena.set_allows_action(defines.input_action.import_permissions_string, false)
  arena.set_allows_action(defines.input_action.delete_permission_group, false)
  arena.set_allows_action(defines.input_action.add_permission_group, false)
  arena.set_allows_action(defines.input_action.activate_paste, false)
  arena.set_allows_action(defines.input_action.activate_cut, false)
  arena.set_allows_action(defines.input_action.activate_copy, false)
  arena.set_allows_action(defines.input_action.alternative_copy, false)
  arena.set_allows_action(defines.input_action.begin_mining, false)
  arena.set_allows_action(defines.input_action.begin_mining_terrain, false)
  arena.set_allows_action(defines.input_action.build_item, false)
  arena.set_allows_action(defines.input_action.build_rail, false)
  arena.set_allows_action(defines.input_action.build_terrain, false)
  arena.set_allows_action(defines.input_action.copy, false)
  arena.set_allows_action(defines.input_action.deconstruct, false)
  arena.set_allows_action(defines.input_action.drop_item, false)
  for i = 1, 4, 1 do
    local force = game.create_force("arena" .. i)
    global.arena.enemies[i] = force
    force.maximum_following_robot_count = 100
    force.following_robots_lifetime_modifier = 600
    force.set_ammo_damage_modifier("combat-robot-beam", 1)
    force.set_gun_speed_modifier("biological", 2)
  end
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(1, arena_ticker)
Event.on_nth_tick(60, tick)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_pre_player_died, on_pre_player_died)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
