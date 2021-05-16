
    -- tank battles (royale) -- mewmew and xalpha made this --

    -- local Schedule = require 'maps.tank_battles.on_tick_schedule'

    require 'maps.tank_battles.on_tick_schedule'

    global.game_players_memory = {}

    global.table_of_properties = {}

    global.required_number_of_players = 1

    global.countdown_in_ticks = 54000

    global.battle_tick = 0

    global.wait_in_seconds = 15

    global.arena_size = 1000

    global.arena_tree_chance = 4

    global.arena_tree_noise = 75

    global.loot_box_chance = 1000

    global.noise_seed = 0

    global.game_players_memory = {}

    global.entity_tree = {}

    global.entity_secret = 'inserter'

    global.surface_entry_point = ''

    global.distance_to_orbit = 0

    global.orbit_reduction_interval = 0

    global.game_stage = 'lobby'

    local simplex_noise = require 'utils.simplex_noise'.d2

    local function initialize_permissions()

        local permission_spectator = game.permissions.create_group( 'permission_spectator' )

        for key, _ in pairs( defines.input_action ) do permission_spectator.set_allows_action( defines.input_action[ key ], false ) end

        local table_of_allowed_actions = { defines.input_action.admin_action, defines.input_action.gui_checked_state_changed, defines.input_action.gui_click, defines.input_action.gui_confirmed, defines.input_action.gui_elem_changed, defines.input_action.gui_location_changed, defines.input_action.gui_selected_tab_changed, defines.input_action.gui_selection_state_changed, defines.input_action.gui_switch_state_changed, defines.input_action.gui_text_changed, defines.input_action.gui_value_changed, defines.input_action.open_gui, defines.input_action.open_kills_gui, defines.input_action.start_walking, defines.input_action.toggle_show_entity_info, defines.input_action.write_to_console, defines.input_action.edit_permission_group, defines.input_action.edit_custom_tag }

        for _, action in pairs( table_of_allowed_actions ) do permission_spectator.set_allows_action( action, true ) end

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.grab_blueprint_record, false )

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.import_blueprint_string, false )

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.import_blueprint, false )

    end

    local function initialize_forces()

        game.create_force( 'force_spectator' )

        local force = game.forces.force_spectator

        force.set_cease_fire( 'enemy', true )

        force.friendly_fire = false

        force.share_chart = true

        force = game.forces.enemy

        force.set_cease_fire( 'force_spectator', true )

    end

    local function initialize_surface_standard()

        game.map_settings.enemy_expansion.enabled = false

        game.map_settings.enemy_evolution.time_factor = 0

        game.map_settings.enemy_evolution.destroy_factor = 0

        game.map_settings.enemy_evolution.pollution_factor = 0

        game.map_settings.pollution.enabled = false

        local mgs = {}

        mgs.width = global.arena_size

        mgs.height = global.arena_size

        mgs.seed = math.random( 1, 2097152 )

        mgs.water = 'none'

        mgs.starting_area = 'none'

        mgs.cliff_settings = { name = 'cliff', cliff_elevation_0 = 0, cliff_elevation_interval = 0 }

        mgs.autoplace_controls = { [ 'trees' ] = { frequency = 'normal', size = 'normal', richness = 'normal' }, [ 'coal' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'stone' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'copper-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'uranium-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'iron-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'crude-oil' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'enemy-base' ] = { frequency = 'normal', size = 'normal', richness = 'normal' } }

        mgs.autoplace_settings = { entity = { treat_missing_as_default = false, settings = { frequency = 'none', size = 'none', richness = 'none' } }, decorative = { treat_missing_as_default = true, settings = { frequency = 'none', size = 'none', richness = 'none' } } }

        mgs.default_enable_all_autoplace_controls = true

        if game.surfaces.tank_battles == nil then

            game.create_surface( 'tank_battles', mgs )

        else

            rendering.clear()

            game.surfaces.tank_battles.clear()

            game.surfaces.tank_battles.map_gen_settings = mgs

         end

        game.surfaces.tank_battles.force_generate_chunk_requests()

    end

    local function initialize_surface_customize()

        local tree_raffle = {}

        for _, entity in pairs( game.entity_prototypes ) do

            if entity.type == 'tree' then table.insert( tree_raffle, entity.name ) end

        end

        global.entity_tree = tree_raffle[ math.random( 1, #tree_raffle ) ]

        global.arena_tree_chance = math.random( 4, 20 )

        global.arena_tree_noise = math.random( 0, 75 ) * 0.01

        local entity_raffle = {}

        local table_of_items = { 'furnace', 'assembling-machine', 'power-switch', 'programmable-speaker', 'reactor' }

        for _, entity in pairs( game.entity_prototypes ) do

            for _, item in pairs( table_of_items ) do

                if entity.type == item then table.insert( entity_raffle, entity.name ) end

            end

        end

        global.entity_secret = entity_raffle[ math.random( 1, #entity_raffle ) ]

    end

    local function get_noise( name, position )

        local seed = global.noise_seed

        local noise = {}

        local noise_seed_add = 25000

        if name == 'rocks_one' then

            noise[ 1 ] = simplex_noise( position.x * 0.02, position.y * 0.02, seed )

            seed = seed + noise_seed_add

            noise[ 2 ] = simplex_noise( position.x * 0.1, position.y * 0.1, seed )

            return noise[ 1 ] + noise[ 2 ] * 0.2

        end

        seed = seed + noise_seed_add

        seed = seed + noise_seed_add

        if name == 'rocks_two' then

            noise[ 1 ] = simplex_noise( position.x * 0.02, position.y * 0.02, seed )

            seed = seed + noise_seed_add

            noise[ 2 ] = simplex_noise( position.x * 0.1, position.y * 0.1, seed )

            return noise[ 1 ] + noise[ 2 ] * 0.2

        end

    end

    local function angle_to_position( position, angle, distance )

        local deg_to_rad_factor = math.pi / 180

        angle = angle * deg_to_rad_factor

        return { x = position.x + math.cos( angle ) * distance, y = position.y + math.sin( angle ) * distance }

    end

    local function get_valid_random_spawn_position()

        local distance_to_orbit = global.distance_to_orbit - 25

        if distance_to_orbit <= 16 then return { x = 16, y = 0 } end

        return angle_to_position( { x = 0, y = 0 }, math.random( 0, 360 ), math.random( 16, distance_to_orbit ) )

    end

    local function entity_to_arena( surface, tile_position )

        local tile = surface.get_tile( tile_position )

        if tile.name == 'water' or tile.name == 'deepwater' or tile.name == 'out-of-map' then return end

        local noise_one = get_noise( 'rocks_one', tile_position )

        local noise_two = get_noise( 'rocks_two', tile_position )

        if noise_one > - 0.1 and noise_one < 0.1 and noise_two > - 0.3 and noise_two < 0.3 then

            return surface.create_entity( { name = 'rock-big', position = tile_position } )

        end

        if math.random( 1, global.arena_tree_chance ) == 1 and noise_one > global.arena_tree_noise then

            return surface.create_entity( { name = global.entity_tree, position = tile_position } )

        end

        if math.random( 1, 1024 ) ~= 1 then return end

        if math.random( 1, 16 ) == 1 then

            if surface.can_place_entity( { name = global.entity_secret, position = tile_position, force = 'enemy' } ) then

                return surface.create_entity( { name = global.entity_secret, position = tile_position, force = 'enemy' } )

            end

        end

        if math.random( 1, 64 ) == 1 and surface.can_place_entity( { name = 'big-worm-turret', position = tile_position, force = 'enemy' } ) then

            return surface.create_entity( { name = 'big-worm-turret', position = tile_position, force = 'enemy' } )

        end

        if math.random( 1, 32 ) == 1 and surface.can_place_entity( { name = 'medium-worm-turret', position = tile_position, force = 'enemy' } ) then

            return surface.create_entity( { name = 'medium-worm-turret', position = tile_position, force = 'enemy' } )

        end

        if math.random( 1, 512 ) == 1 and  surface.can_place_entity( { name = 'behemoth-biter', position = tile_position, force = 'enemy' } ) then

            return surface.create_entity( { name = 'behemoth-biter', position = tile_position, force = 'enemy' } )

        end

        if math.random( 1, 64 ) == 1 and surface.can_place_entity( { name = 'big-biter', position = tile_position, force = 'enemy' } ) then

            return surface.create_entity( { name = 'big-biter', position = tile_position, force = 'enemy' } )

        end

    end

    local function draw_circle_lobby( surface, spawn_diameter, spawn_position )

        for x = - spawn_diameter, spawn_diameter do for y = - spawn_diameter, spawn_diameter do

            local tile_position = { x = spawn_position.x + x, y = spawn_position.y + y }

            local distance_to_center = math.sqrt( tile_position.x ^ 2 + tile_position.y ^ 2 )

            local tile_name = false

            if distance_to_center < spawn_diameter then tile_name = 'water' end

            if distance_to_center < 9.5 then tile_name = 'refined-concrete' end

            if distance_to_center < 9 then tile_name = 'concrete' end

            if distance_to_center < 3.5 then tile_name = 'refined-concrete' end

            if tile_name then

                local table_of_entities = surface.find_entities_filtered( { position = tile_position, radius = 0.8 } )

                for _, entity in pairs( table_of_entities ) do entity.destroy() end

                surface.destroy_decoratives( { position = tile_position } )

                surface.set_tiles( { { name = tile_name, position = tile_position } }, true )

                if math.random( 1, 32 ) == 1 and tile_name == 'water' then surface.create_entity( { name = 'fish', position = tile_position } ) end

            end

        end end

    end

    local function tile_to_water( tile_position )

        local surface = game.surfaces.tank_battles

        local tile = surface.get_tile( tile_position )

        if tile.valid and tile.name ~= 'water' and tile.name ~= 'deepwater' and tile.name ~= 'concrete' and tile.name ~= 'refined-concrete' and tile.name ~= 'out-of-map' then

            local table_of_entities = surface.find_entities_filtered( { position = tile_position, radius = 0.8 } )

            for _, entity in pairs( table_of_entities ) do

                if entity.name == 'character' then entity.die( 'enemy' ) else entity.destroy() end

            end

            surface.destroy_decoratives( { position = tile_position } )

            surface.set_tiles( { { name = 'water', position = tile_position } }, true )

        end

    end

    -- local function blow_up_the_ground( position_of_center )

    --     local table_of_items = {}

    --     for x = -74, 74 do for y = -74, 74 do

    --         local tile_position = { x = position_of_center.x + x, y = position_of_center.y + y }

    --         local distance_to_center = math.ceil( math.sqrt( ( tile_position.x - position_of_center.x ) ^ 2 + ( tile_position.y - position_of_center.y ) ^ 2 ) )

    --         if distance_to_center <= 37 then

    --             if not table_of_items[ distance_to_center ] then table_of_items[ distance_to_center ] = {} end

    --             table_of_items[ distance_to_center ][ #table_of_items[ distance_to_center ] + 1 ] = tile_position

    --         end

    --     end end

    --     if #table_of_items == 0 then return end

    --     local next_tick = 1

    --     for index_one, table_of_tiles in pairs( table_of_items ) do

    --         for index_two, tile_position in pairs( table_of_tiles ) do schedule_execute_on_tick( game.tick + next_tick, tile_to_water, { tile_position } ) end

    --         next_tick = next_tick + 2

    --     end

    -- end

    local function create_atomic_rocket( player, position_of_launch, position_of_impact )

        local entity = player.surface.create_entity( { name = 'atomic-rocket', force = 'enemy', speed = 0, max_range = 1750, position = position_of_launch, target = position_of_impact } )

        player.print( 'ATTENTION: NUCLEAR LAUNCH DETECTED', { r = 0.9, g = 0, b = 0 } )

        player.add_custom_alert( entity, { type = 'item', name = 'atomic-bomb' }, 'NUCLEAR LAUNCH DETECTED', false )

        player.play_sound( { path = 'utility/alert_destroyed', position = position_of_impact, volume_modifier = 1 }  )

    end

    local function launch_atomic_rocket( player )

        local position_of_impact = player.position

        local angle = math.random( 0, 360 )

        local distance = 1750

        local position_of_launch = angle_to_position( position_of_impact, angle, distance )

        local moment_of_launch = 1

        local moment_of_impact = 840

        rendering.draw_sprite( { surface = player.surface, target = position_of_impact, time_to_live = moment_of_launch + moment_of_impact, sprite = 'utility/shoot_cursor_red', draw_on_ground = true } )

        schedule_execute_on_tick( game.tick + moment_of_launch, create_atomic_rocket, { player, position_of_launch, position_of_impact } )

        -- It looks good, but it creates a bottleneck if there are too many players.

        -- schedule_execute_on_tick( game.tick + moment_of_launch + moment_of_impact, blow_up_the_ground, { position_of_impact } )

    end

    local function do_shrink_circle()

        local distance_to_orbit = global.distance_to_orbit

        if distance_to_orbit <= 0 then return end

        local position_of_center = { x = 0, y = 0 }

        local next_tick = game.tick + 1

        for angle = 0, 360, 0.35 do

            local tile_position = angle_to_position( position_of_center, angle, distance_to_orbit )

            for x = -1, 1, 1 do for y = -1, 1, 1 do

                local area_position = { x = tile_position.x + x, y = tile_position.y + y }

                schedule_execute_on_tick( next_tick + math.random( 0, 8 ), tile_to_water, { area_position } )

            end end

            next_tick = game.tick + math.random( 1, global.orbit_reduction_interval )

        end

        global.distance_to_orbit = global.distance_to_orbit - 1

    end

    local function create_a_tank( player )

        if not global.game_players_memory[ player.index ] then return end

        if not global.game_players_memory[ player.index ].in_battle then return end

        local position = player.surface.find_non_colliding_position( 'tank', player.position, 32, 4 )

        if not position then return { x = 16, y = 0 } end

        local entity = player.surface.create_entity( { name = 'tank', position = position, force = player.force.name, direction = math.random( 0, 7 ) } )

        if not entity then return end

        entity.minable = false

        entity.last_user = player.name

        entity.insert( { name = 'wood', count = 50 } )

        entity.insert( { name = 'cannon-shell', count = 200 } )

        entity.set_driver( player )

        if global.game_players_memory[ player.index ] then global.game_players_memory[ player.index ].tank = entity end

    end

    local function destroy_a_tank( player )

        if not global.game_players_memory[ player.index ] then return end

        if not global.game_players_memory[ player.index ].tank then return end

        if not global.game_players_memory[ player.index ].tank.valid then return end

        global.game_players_memory[ player.index ].tank.clear_items_inside()

        global.game_players_memory[ player.index ].tank.destroy()

        global.game_players_memory[ player.index ].tank = nil

    end

    function event_on_click_battle( player )

        if global.game_players_memory[ player.index ] then global.game_players_memory[ player.index ].in_battle = true end

        game.permissions.get_group( 'Default' ).add_player( player )

        player.force = game.forces[ 'force_player_' .. player.index ]

        if player.character then

            player.character.clear_items_inside()

            player.character.destroy()

            player.character = nil

        end

        player.create_character()

        if player.character then player.character.destructible = true end

        if player.character then player.character.disable_flashlight() end

        player.insert( { name = 'raw-fish', count = 10 } )

        player.insert( { name = 'modular-armor', count = 1 } )

        player.insert( { name = 'submachine-gun', count = 1 } )

        player.insert( { name = 'rocket-launcher', count = 1 } )

        player.insert( { name = 'combat-shotgun', count = 1 } )

        local surface = game.surfaces.tank_battles

        local position = get_valid_random_spawn_position( surface )

        player.teleport( position, surface )

        schedule_execute_on_tick( game.tick + 120, create_a_tank, { player } )

    end

    function event_on_click_lobby( player )

        if global.game_players_memory[ player.index ] then global.game_players_memory[ player.index ].in_battle = false end

        game.permissions.get_group( 'permission_spectator' ).add_player( player )

        player.force = game.forces.force_spectator

        destroy_a_tank( player )

        if player.character then

            player.character.clear_items_inside()

            player.character.destroy()

            player.character = nil

        end

        player.create_character()

        if player.character then player.character.destructible = false end

        if player.character then player.character.disable_flashlight() end

        local surface = global.surface_entry_point

        if surface.is_chunk_generated( { x = 0, y = 0 } ) then player.teleport( surface.find_non_colliding_position( 'character', { x = 0, y = 0 }, 9, 0.5 ), surface ) else player.teleport( { x = 0, y = 0 }, surface ) end

    end

    -- function shuffle( table_of_items )

    --     local length_of_items = #table_of_items

    --     for index = length_of_items, 1, - 1 do

    --         local random = math.random( length_of_items )

    --         table_of_items[ index ], table_of_items[ random ] = table_of_items[ random ], table_of_items[ index ]

    --     end

    --     return table_of_items

    -- end

    local function on_init()

        game.surfaces.nauvis.clear()

        game.surfaces.nauvis.map_gen_settings = { width = 32, height = 32 }

        game.surfaces.nauvis.always_day = true

        game.create_surface( 'tank_battles', { width = 1, height = 1 } )

        initialize_permissions()

        initialize_forces()

        global.surface_entry_point = game.surfaces.nauvis

        global.distance_to_orbit = global.arena_size / 2

        global.orbit_reduction_interval = math.ceil( global.countdown_in_ticks / global.distance_to_orbit )

        -- global.game_stage = 'do_nothing'

    end

    local function on_tick()

        if global.game_stage == 'ongoing_game' then

            local battle_tick = game.tick - global.battle_tick

            if battle_tick > 0 and battle_tick % 10800 == 0 then

                for _, player in pairs( game.connected_players ) do

                    if global.game_players_memory[ player.index ].in_battle then launch_atomic_rocket( player ) end

                end

            end

            if game.tick % global.orbit_reduction_interval == 0 then

                local number_of_players = 0

                for _, player in pairs( global.game_players_memory ) do

                    if player.in_battle then number_of_players = number_of_players + 1 end

                end

                if number_of_players >= 1 then do_shrink_circle() end

                if global.distance_to_orbit == 150 then

                    game.print( 'Resuscitation is now disabled, the last survivor wins the round.' )

                    global.orbit_reduction_interval = global.orbit_reduction_interval * 3

                end

                if global.distance_to_orbit == 13 then

                    game.print( 'It seems like players went swimming. The round is now restarted without scoring.' )

                    global.game_stage = 'round_is_over'

                end

            end

        end

        if game.tick % 60 ~= 0 then return end

        if global.game_stage == 'round_is_over' then

            -- local version = game.active_mods[ 'base' ]

            game.reset_time_played() -- 0.18

            global.distance_to_orbit = global.arena_size / 2

            global.orbit_reduction_interval = math.ceil( global.countdown_in_ticks / global.distance_to_orbit )

            global.surface_entry_point = game.surfaces.nauvis

            global.wait_in_seconds = 15

            global.game_stage = 'lobby'

            for _, player in pairs( game.connected_players ) do

                event_on_click_lobby( player )

                show_gui_player_scoreboard( player )

                hide_gui_player_camera( player )

            end

        end

        if global.game_stage == 'ongoing_game' then

            local number_of_survivors = 0

            local number_of_fighters = 0

            for _, player in pairs( global.game_players_memory ) do

                if player.in_battle then number_of_survivors = number_of_survivors + 1 end

                if not player.is_spectator then number_of_fighters = number_of_fighters + 1 end

            end

            if number_of_survivors <= 1 and number_of_fighters >= 2 then

                if number_of_survivors == 1 then

                    local player_index = nil

                    for index, player in pairs( global.game_players_memory ) do

                        if player.in_battle then player_index = index end

                    end

                    global.game_players_memory[ player_index ].won_rounds = global.game_players_memory[ player_index ].won_rounds + 1

                    global.game_players_memory[ player_index ].in_battle = false

                    game.print( game.players[ player_index ].name .. ' has won the round!' )

                end

                if number_of_survivors == 0 then game.print( 'No alive players! Round ends in a draw!' ) end

                global.game_stage = 'round_is_over'

            end

        end

        if global.game_stage == 'teleport_the_players' then

            for _, player in pairs( game.connected_players ) do

                if global.game_players_memory[ player.index ].is_spectator then

                    event_on_click_lobby( player )

                else

                    event_on_click_battle( player )

                end

                hide_gui_player_scoreboard( player )

            end

            game.surfaces.tank_battles.daytime = 0.15

            game.surfaces.tank_battles.always_day = false

            game.surfaces.tank_battles.freeze_daytime = false

            global.battle_tick = game.tick

            global.game_stage = 'ongoing_game'

        end

        if global.game_stage == 'check_the_number_of_players_who_want_to_fight' then

            local number_of_players = 0

            for _, player in pairs( global.game_players_memory ) do

                if not player.is_spectator then number_of_players = number_of_players + 1 end

            end

            if number_of_players >= global.required_number_of_players then

                global.game_stage = 'teleport_the_players'

            end

        end

        if global.game_stage == 'preparing_spawn_positions' then

            schedule_execute_on_tick( game.tick + 1, draw_circle_lobby, { game.surfaces.tank_battles, 14, { x = 0, y = 0 } } )

            global.surface_entry_point = game.surfaces.tank_battles

            global.game_stage = 'check_the_number_of_players_who_want_to_fight'

        end

        if global.game_stage == 'check_the_process_of_creating_the_surface' then

            if game.surfaces.tank_battles.is_chunk_generated( { x = 0, y = 0 } ) then

                global.game_stage = 'preparing_spawn_positions'

            else

                game.surfaces.tank_battles.request_to_generate_chunks( { x = 0, y = 0 }, 1 )

            end

        end

        if global.game_stage == 'regenerate_the_customize_surface' then

            initialize_surface_standard()

            initialize_surface_customize()

            global.game_stage = 'check_the_process_of_creating_the_surface'

        end

        if global.game_stage == 'lobby' then

            local number_of_players = 0

            for _, player in pairs( global.game_players_memory ) do

                if not player.is_spectator then number_of_players = number_of_players + 1 end

            end

            if number_of_players >= global.required_number_of_players and global.wait_in_seconds > 0 then

                if global.wait_in_seconds % 10 == 0 then game.print( 'The round starts in ' .. global.wait_in_seconds .. ' seconds.' ) end

                global.wait_in_seconds = global.wait_in_seconds - 1

            end

            if global.wait_in_seconds == 0 then global.game_stage = 'regenerate_the_customize_surface' end

        end

    end


    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        player.minimap_enabled = false

        player.game_view_settings = { show_controller_gui = true, show_minimap = false, show_research_info = false, show_entity_info = true, show_alert_gui = true, update_entity_selection = true, show_rail_block_visualisation = false, show_side_menu = false, show_map_view_options = false, show_quickbar = true, show_shortcut_bar = false }

        if not global.game_players_memory[ player.index ] then global.game_players_memory[ player.index ] = { in_battle = false, is_spectator = false, won_rounds = 0, player_killed = 0, tank = nil, spawn = nil } end

        if not game.forces[ 'force_player_' .. player.index ] then

            game.create_force( 'force_player_' .. player.index )

            local force = game.forces[ 'force_player_' .. player.index ]

            force.set_friend( 'force_spectator', true )

            force.set_ammo_damage_modifier( 'capsule', - 0.5 )

            force.set_ammo_damage_modifier( 'laser', - 0.7 )

            force.set_ammo_damage_modifier( 'beam', - 0.9 )

            -- force.set_ammo_damage_modifier( 'laser-turret', - 0.7 )

            -- force.set_ammo_damage_modifier( 'combat-robot-beam', - 0.9 )

            -- force.set_ammo_damage_modifier( 'combat-robot-laser', - 0.9 )

            force.technologies[ 'follower-robot-count-1' ].researched = true

            force.technologies[ 'follower-robot-count-2' ].researched = true

            force.technologies[ 'toolbelt' ].researched = true

            force.research_queue_enabled = true

            force.friendly_fire = false

            force.share_chart = true

        end

        if player.online_time == 0 and global.game_stage == 'ongoing_game' then

            event_on_click_battle( player )

        else

            event_on_click_lobby( player )

        end

        if global.is_the_nauvis_lobby_drawn == nil then

            schedule_execute_on_tick( game.tick + 1, draw_circle_lobby, { game.surfaces.nauvis, 14, { x = 0, y = 0 } } )

            global.is_the_nauvis_lobby_drawn = true

        end

    end

    local function on_player_respawned( event )

        local player = game.players[ event.player_index ]

        if global.distance_to_orbit <= 150 then

            event_on_click_lobby( player )

        else

            event_on_click_battle( player )

        end

    end

    local function on_player_died( event )

        local player = game.players[ event.player_index ]

        destroy_a_tank( player )

        if global.distance_to_orbit <= 150 then

            player.ticks_to_respawn = 0

        else

            player.ticks_to_respawn = 960

        end

        local player_name_of_the_causer = nil

        local player_death_message = player.name .. ' was killed.'

        if event.cause and event.cause.valid then

            if event.cause.name == 'character' then

                global.game_players_memory[ event.cause.player.index ].player_killed = global.game_players_memory[ event.cause.player.index ].player_killed + 1

                player_name_of_the_causer = event.cause.player.name

                player_death_message = player.name .. ' was killed by the player ' .. event.cause.player.name .. '.'

            elseif event.cause.name == 'car' or event.cause.name == 'tank' or event.cause.name == 'train' then

                local driver = event.cause.get_driver()

                if driver.player then

                    global.game_players_memory[ driver.player.index ].player_killed = global.game_players_memory[ driver.player.index ].player_killed + 1

                    player_name_of_the_causer = driver.player.name

                    player_death_message = player.name .. ' was killed by a ' .. event.cause.name .. ' by the driver ' .. driver.player.name .. '.'

                else

                    player_death_message = player.name .. ' was killed by a ' .. event.cause.name .. '.'

                end

            elseif event.cause.name then

                player_death_message = player.name .. ' was killed by a ' .. event.cause.name .. '.'

            end

        end

        for _, p in pairs( game.connected_players ) do

            if p.force.name ~= player.force.name and p.name ~= player_name_of_the_causer then

                p.print( player_death_message, { r = 1, g = 0, b = 1 } )

            end

        end

    end

    local function on_player_left_game( event )

        local player = game.players[ event.player_index ]

        destroy_a_tank( player )

        game.merge_forces( 'force_player_' .. player.index, 'neutral' )

        if global.game_players_memory[ player.index ] then global.game_players_memory[ player.index ] = nil end

    end

    local function on_console_chat( event )

        if not event.message then return end

        if not event.player_index then return end

        local player = game.players[ event.player_index ]

        local color = { r = player.color.r * 0.6 + 0.4, g = player.color.g * 0.6 + 0.4, b = player.color.b * 0.6 + 0.4, a = 1 }

        if player.force.name == 'force_spectator' and event.message:find( '%[gps=%s*%-?%d+%,?%s*%-?%d+%]' ) then

            event.message = event.message:gsub( '%[gps=%s*%-?%d+%,?%s*%-?%d+%]', '' )

            player.print( 'As a spectator, you cannot send location information.' )

        else

            for _, p in pairs( game.connected_players ) do

                if p.force.name ~= player.force.name  then p.force.print( player.name .. ': '.. event.message, color ) end

            end

        end

    end

    local function on_chunk_generated( event )

        if event.surface.name == 'nauvis' then return end

        if not global.noise_seed then global.noise_seed = math.random( 1, 2097152 ) end

        local chunk_position = { x = event.area.left_top.x, y = event.area.left_top.y }

        for x = 0, 31 do for y = 0, 31 do

            local tile_position = { x = chunk_position.x + x, y = chunk_position.y + y }

            entity_to_arena( event.surface, tile_position )

        end end

    end

    local function on_chunk_charted( event )

        if event.force.name == 'force_spectator' then return end

        event.force.clear_chart()

    end

    local function on_marked_for_deconstruction( event )

        event.entity.cancel_deconstruction( game.players[ event.player_index ].force.name )

    end


    local function on_picked_up_item( event )

        if global.game_stage ~= 'ongoing_game' then return end

        if event.item_stack.name == 'stone' then

            local player = game.players[ event.player_index ]

            local player_inventory = player.get_inventory( defines.inventory.character_main )

            local item_count = player_inventory.get_item_count( 'stone' )

            if item_count > 0 then player_inventory.remove( { name = 'stone', count = 1 } ) end

        end

    end

    -- require 'maps.tank_battles.module_player_color'

    require 'maps.tank_conquest.module_loot_boxes'

    require 'maps.tank_conquest.module_player_damage'

    require 'maps.tank_battles.module_scenario_introduction'

    -- require 'maps.tank_conquest.module_support_request'

    require 'maps.tank_conquest.module_player_belt'

    require 'maps.tank_battles.module_player_settings'

    require 'maps.tank_battles.module_player_scoreboard'

    local Event = require 'utils.event'

    Event.on_init( on_init )

    Event.add( defines.events.on_tick, on_tick )

    Event.add( defines.events.on_chunk_generated, on_chunk_generated )

    Event.add( defines.events.on_chunk_charted, on_chunk_charted )

    Event.add( defines.events.on_picked_up_item, on_picked_up_item )

    Event.add( defines.events.on_console_chat, on_console_chat )

    Event.add( defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction )

    Event.add( defines.events.on_player_joined_game, on_player_joined_game )

    Event.add( defines.events.on_player_respawned, on_player_respawned )

    Event.add( defines.events.on_player_died, on_player_died )

    Event.add( defines.events.on_player_left_game, on_player_left_game )
