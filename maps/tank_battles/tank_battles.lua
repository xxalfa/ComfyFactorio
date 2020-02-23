
    -- tank battles (royale)-- mewmew and xalpha made this --

    local utils = require 'utils.utils'

    local event = require 'utils.event'

    local table_insert = table.insert

    local math_random = math.random

    local map_functions = require 'tools.map_functions'

    local simplex_noise = require 'utils.simplex_noise'

    simplex_noise = simplex_noise.d2

    global.table_of_properties = {}

    global.table_of_properties.required_number_of_players = 1

    global.table_of_properties.countdown_in_ticks = 54000

    global.table_of_properties.arena_size = 1000

    global.table_of_properties.distance_to_orbit = 0

    global.table_of_properties.circle_interval = 0

    global.table_of_properties.arena_tree_chance = 0

    global.table_of_properties.arena_tree_noise = 0

    global.table_of_properties.loot_box_chance = 1000

    global.table_of_properties.game_stage = 'lobby'

    global.table_of_players = {}

    global.entity_tree = {}

    global.entity_secret = {}

    local function initialize_permissions()

        local permission = game.permissions.create_group( 'permission_spectator' )

        for key, value in pairs( defines.input_action ) do permission.set_allows_action( defines.input_action[ key ], false ) end

        local table_of_definitions = { defines.input_action.gui_checked_state_changed, defines.input_action.gui_click, defines.input_action.gui_confirmed, defines.input_action.gui_elem_changed, defines.input_action.gui_location_changed, defines.input_action.gui_selected_tab_changed, defines.input_action.gui_selection_state_changed, defines.input_action.gui_switch_state_changed, defines.input_action.gui_text_changed, defines.input_action.gui_value_changed, defines.input_action.start_walking, defines.input_action.open_kills_gui, defines.input_action.toggle_show_entity_info, defines.input_action.write_to_console, defines.input_action.edit_permission_group }

        for _, define in pairs( table_of_definitions ) do permission.set_allows_action( define, true ) end

        local permission = game.permissions.get_group( 'Default' )

        permission.set_allows_action( defines.input_action.grab_blueprint_record, false )

        permission.set_allows_action( defines.input_action.import_blueprint_string, false )

        permission.set_allows_action( defines.input_action.import_blueprint, false )

    end

    local function initialize_surface_standard()

        game.map_settings.enemy_expansion.enabled = false

        game.map_settings.enemy_evolution.time_factor = 0

        game.map_settings.enemy_evolution.destroy_factor = 0

        game.map_settings.enemy_evolution.pollution_factor = 0

        game.map_settings.pollution.enabled = false

        local map_gen_settings = {}

        map_gen_settings.width = global.table_of_properties.arena_size

        map_gen_settings.height = global.table_of_properties.arena_size

        map_gen_settings.seed = math.random( 1, 2097152 )

        map_gen_settings.water = 'none'

        map_gen_settings.starting_area = 'none'

        map_gen_settings.cliff_settings = { name = 'cliff', cliff_elevation_0 = 0, cliff_elevation_interval = 0 }

        map_gen_settings.autoplace_controls = { [ 'trees' ] = { frequency = 'normal', size = 'normal', richness = 'normal' }, [ 'coal' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'stone' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'copper-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'uranium-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'iron-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'crude-oil' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'enemy-base' ] = { frequency = 'normal', size = 'normal', richness = 'normal' } }

        map_gen_settings.autoplace_settings = { entity = { treat_missing_as_default = false, settings = { frequency = 'none', size = 'none', richness = 'none' } }, decorative = { treat_missing_as_default = true, settings = { frequency = 'none', size = 'none', richness = 'none' } } }

        map_gen_settings.default_enable_all_autoplace_controls = true

        if game.surfaces.tank_battles == nil then

            game.create_surface( 'tank_battles', map_gen_settings )

        else

            rendering.clear()

            game.surfaces.tank_battles.clear()

            game.surfaces.tank_battles.map_gen_settings = map_gen_settings

         end

    end

    local function initialize_surface_customize()

        global.table_of_properties.noise_seed = nil

        local tree_raffle = {}

        for _, entity in pairs( game.entity_prototypes ) do

            if entity.type == 'tree' then table.insert( tree_raffle, entity.name ) end

        end

        global.entity_tree = tree_raffle[ math_random( 1, #tree_raffle ) ]

        global.table_of_properties.arena_tree_chance = math_random( 4, 20 )

        global.table_of_properties.arena_tree_noise = math_random( 0, 75 ) * 0.01

        local entity_raffle = {}

        local table_of_items = { 'furnace', 'assembling-machine', 'power-switch', 'programmable-speaker', 'reactor' }

        for _, entity in pairs( game.entity_prototypes ) do

            for _, item in pairs( table_of_items ) do

                if entity.type == item then table.insert( entity_raffle, entity.name ) end

            end

        end

        global.entity_secret = entity_raffle[ math_random( 1, #entity_raffle ) ]

    end

    local function get_noise( name, position )

        local seed = global.table_of_properties.noise_seed

        local noise = {}

        local noise_seed_add = 25000

        if name == 'rocks_one' then

            noise[ 1 ] = simplex_noise( position.x * 0.02, position.y * 0.02, seed )

            seed = seed + noise_seed_add

            noise[ 2 ] = simplex_noise( position.x * 0.1, position.y * 0.1, seed )

            seed = seed + noise_seed_add

            local noise = noise[ 1 ] + noise[ 2 ] * 0.2

            return noise

        end

        seed = seed + noise_seed_add

        seed = seed + noise_seed_add

        if name == 'rocks_two' then

            noise[ 1 ] = simplex_noise( position.x * 0.02, position.y * 0.02, seed )

            seed = seed + noise_seed_add

            noise[ 2 ] = simplex_noise( position.x * 0.1, position.y * 0.1, seed )

            seed = seed + noise_seed_add

            local noise = noise[ 1 ] + noise[ 2 ] * 0.2

            return noise

        end

    end

    local function get_valid_random_spawn_position( surface )

        local arena_size = global.table_of_properties.arena_size

        local table_of_chunks = {}

        for chunk_position in surface.get_chunks() do table_insert( table_of_chunks, { x = chunk_position.x, y = chunk_position.y } ) end

        table_of_chunks = shuffle( table_of_chunks )

        for _, chunk_position in pairs( table_of_chunks ) do

            if chunk_position.x * 32 < arena_size and chunk_position.y * 32 < arena_size and chunk_position.x * 32 >= arena_size * - 1 and chunk_position.y * 32 >= arena_size * - 1 then

                local area = { { chunk_position.x * 32 - 64, chunk_position.y * 32 - 64 }, { chunk_position.x * 32 + 64, chunk_position.y * 32 + 64 } }

                if surface.count_entities_filtered( { name = 'tank', type = 'rock', area = area } ) == 0 then

                    local position = surface.find_non_colliding_position( 'tank', { chunk_position.x * 32 + 16, chunk_position.y * 32 + 16 }, 16, 8 )

                    if position then return position end

                end

            end

        end

        local position = surface.find_non_colliding_position( 'tank', { x = 0, y = 50 }, 32, 4 )

        if position then return position end

        return { x = 0, y = 50 }

    end

    local function entity_to_arena( surface, tile_position )

        local tile = surface.get_tile( tile_position )

        if tile.name == 'water' or tile.name == 'deepwater' or tile.name == 'out-of-map' then return end

        local noise_one = get_noise( 'rocks_one', tile_position )

        local noise_two = get_noise( 'rocks_two', tile_position )

        if noise_one > - 0.1 and noise_one < 0.1 and noise_two > - 0.3 and noise_two < 0.3 then

            return surface.create_entity( { name = 'rock-big', position = tile_position } )

        end

        if math_random( 1, global.table_of_properties.arena_tree_chance ) == 1 and noise_one > global.table_of_properties.arena_tree_noise then

            return surface.create_entity( { name = global.entity_tree, position = tile_position } )

        end

        if math_random( 1, 1024 ) ~= 1 then return end

        if math_random( 1, 16 ) == 1 and surface.can_place_entity( { name = global.entity_secret, position = tile_position, force = 'enemy' } ) then

            return surface.create_entity( { name = global.entity_secret, position = tile_position, force = 'enemy' } )

        end

        if math_random( 1, 64 ) == 1 and surface.can_place_entity( { name = 'big-worm-turret', position = tile_position, force = 'enemy' } ) then

            return surface.create_entity( { name = 'big-worm-turret', position = tile_position, force = 'enemy' } )

        end

        if math_random( 1, 32 ) == 1 and surface.can_place_entity( { name = 'medium-worm-turret', position = tile_position, force = 'enemy' } ) then

            return surface.create_entity( { name = 'medium-worm-turret', position = tile_position, force = 'enemy' } )

        end

        if math_random( 1, 512 ) == 1 and  surface.can_place_entity( { name = 'behemoth-biter', position = tile_position, force = 'enemy' } ) then

            return surface.create_entity( { name = 'behemoth-biter', position = tile_position, force = 'enemy' } )

        end

        if math_random( 1, 64 ) == 1 and surface.can_place_entity( { name = 'big-biter', position = tile_position, force = 'enemy' } ) then

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

                surface.set_tiles( { { name = tile_name, position = tile_position } }, true )

                surface.destroy_decoratives( { position = tile_position } )

                local table_of_entities = surface.find_entities_filtered( { position = tile_position, radius = 0.8 } )

                for _, entity in pairs( table_of_entities ) do entity.destroy() end

                if math.random( 1, 32 ) == 1 and tile_name == 'water' then surface.create_entity( { name = 'fish', position = tile_position } ) end

            end

        end end

    end

    local function tile_to_water( tile_position )

        local surface = game.surfaces.tank_battles

        local tile = surface.get_tile( tile_position )

        if tile.valid and tile.name ~= 'water' and tile.name ~= 'deepwater' and tile.name ~= 'concrete' and tile.name ~= 'refined-concrete' and tile.name ~= 'out-of-map' then

            surface.set_tiles( { { name = 'water', position = tile_position } }, true )

            surface.destroy_decoratives( { position = tile_position } )

            local table_of_entities = surface.find_entities_filtered( { position = tile_position, radius = 0.8 } )

            for _, entity in pairs( table_of_entities ) do entity.destroy() end

        end

    end

    local function angle_to_position( position, angle, distance )

        local deg_to_rad_factor = math.pi / 180

        angle = angle * deg_to_rad_factor

        return { x = position.x + math.cos( angle ) * distance, y = position.y + math.sin( angle ) * distance }

    end

    local function blow_up_the_ground( center_position )

        local table_of_items = {}

        for x = -74, 74 do for y = -74, 74 do

            local tile_position = { x = center_position.x + x, y = center_position.y + y }

            local distance_to_center = math.ceil( math.sqrt( ( tile_position.x - center_position.x ) ^ 2 + ( tile_position.y - center_position.y ) ^ 2 ) )

            if distance_to_center <= 37 then

                if not table_of_items[ distance_to_center ] then table_of_items[ distance_to_center ] = {} end

                table_of_items[ distance_to_center ][ #table_of_items[ distance_to_center ] + 1 ] = tile_position

            end

        end end

        if #table_of_items == 0 then return end

        local next_tick = 1

        for index_one, table_of_tiles in pairs( table_of_items ) do

            for index_two, tile_position in pairs( table_of_tiles ) do execute_on_tick( game.tick + next_tick, tile_to_water, { tile_position } ) end

            next_tick = next_tick + 2

        end

    end

    local function create_atomic_rocket( player, position_of_launch, position_of_impact )

        local entity = player.surface.create_entity( { name = 'atomic-rocket', force = 'enemy', speed = 0, max_range = 1750, position = position_of_launch, target = position_of_impact } )

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

        execute_on_tick( game.tick + moment_of_launch, create_atomic_rocket, { player, position_of_launch, position_of_impact } )

        execute_on_tick( game.tick + moment_of_launch + moment_of_impact, blow_up_the_ground, { position_of_impact } )

    end

    local function do_shrink_circle()

        local distance_to_orbit = global.table_of_properties.distance_to_orbit

        if distance_to_orbit <= 0 then return end

        local center_position = { x = 0, y = 0 }

        local table_of_items = {}

        local next_tick = game.tick + 1

        for angle = 0, 360 do

            local tile_position = angle_to_position( center_position, angle, distance_to_orbit )

            for x = -1, 1, 1 do for y = -1, 1, 1 do

                local area_position = { x = tile_position.x + x, y = tile_position.y + y }

                execute_on_tick( next_tick, tile_to_water, { area_position } )

            end end

            next_tick = game.tick + math.random( 1, global.table_of_properties.circle_interval )

        end

        global.table_of_properties.distance_to_orbit = global.table_of_properties.distance_to_orbit - 1

    end

    local function create_a_tank( player )

        local position = player.surface.find_non_colliding_position( 'tank', player.position, 64, 4 )

        if not position then position = { x = 0, y = 50 } end

        local entity = player.surface.create_entity( { name = 'tank', position = position, force = player.force.name } )

        if not entity then return end

        entity.minable = false

        entity.last_user = player.name

        entity.insert( { name = 'wood', count = 50 } )

        entity.insert( { name = 'cannon-shell', count = 50 } )

        entity.set_driver( player )

        global.table_of_players[ player.index ].tank = entity

    end

    function shuffle( table_of_items )

        local length_of_items = #table_of_items

        for index = length_of_items, 1, - 1 do

            local random = math.random( length_of_items )

            table_of_items[ index ], table_of_items[ random ] = table_of_items[ random ], table_of_items[ index ]

        end

        return table_of_items

    end

    local function on_init( event )

        game.surfaces.nauvis.clear()

        game.surfaces.nauvis.map_gen_settings = { width = 10, height = 10 }

        game.create_surface( 'tank_battles', { width = 10, height = 10 } )

        initialize_permissions()

        execute_on_tick( 60, draw_circle_lobby, { game.surfaces.nauvis, 14, { x = 0, y = 0 } } )

        local half_arena_size = global.table_of_properties.arena_size / 2

        global.table_of_properties.distance_to_orbit = math.ceil( math.sqrt( half_arena_size ^ 2 + half_arena_size ^ 2 ) )

        global.table_of_properties.circle_interval = math.ceil( global.table_of_properties.countdown_in_ticks / global.table_of_properties.distance_to_orbit )

        -- global.table_of_properties.game_stage = 'do_nothing'

    end

    event.on_init( on_init )

    local function on_tick( event )

        if game.tick % 60 == 0 then

            if global.table_of_properties.game_stage == 'ongoing_game' then

                local number_of_players = 0

                for _, player in pairs( global.table_of_players ) do

                    if player.in_battle then number_of_players = number_of_players + 1 end

                end

                if number_of_players <= 1 then

                    if number_of_players == 1 then

                        local player_index = nil

                        for index, player in pairs( global.table_of_players ) do

                            if player.in_battle then player_index = index end

                        end

                        global.table_of_players[ player_index ].won_rounds = global.table_of_players[ player_index ].won_rounds + 1

                        global.table_of_players[ player_index ].in_battle = false

                        game.print( game.players[ player_index ].name .. ' has won the battle!', { r = 150, g = 150, b = 0 } )

                    end

                    if number_of_players == 0 then

                        game.print( 'No alive players! Round ends in a draw!', { r = 150, g = 150, b = 0 } )

                    end

                    local surface = game.surfaces.nauvis

                    local position = { x = 0, y = 0 }

                    for _, player in pairs( game.connected_players ) do

                        game.permissions.get_group( 'permission_spectator' ).add_player( player )

                        player.force = game.forces.force_spectator

                        player.character.destructible = false

                        if surface.is_chunk_generated( position ) then player.teleport( surface.find_non_colliding_position( 'character', position, 9, 0.5 ), surface ) else player.teleport( position, surface ) end

                        draw_gui_player_scoreboard( player )

                    end

                    global.table_of_properties.game_stage = 'lobby'

                end

            end

            if global.table_of_properties.game_stage == 'send_the_players_into_the_arena_fully_armed_with_a_tank' then

                local surface = game.surfaces.tank_battles

                for _, player in pairs( game.connected_players ) do

                    local player_properties = global.table_of_players[ player.index ]

                    if not player_properties.is_spectator then

                        player_properties.in_battle = true

                        game.permissions.get_group( 'Default' ).add_player( player )

                        player.force = game.forces[ 'force_player_' .. player.index ]

                        player.character.destructible = true

                        player.character.disable_flashlight()

                        player.insert( { name = 'light-armor', count = 1 } )

                        player.insert( { name = 'raw-fish', count = 10 } )

                        player.insert( { name = 'combat-shotgun', count = 1 } )

                        player.insert( { name = 'flamethrower', count = 1 } )

                        player.insert( { name = 'rocket-launcher', count = 1 } )

                        local position = get_valid_random_spawn_position( surface )

                        player.teleport( position, surface )

                        create_a_tank( player )

                    end

                end

                global.table_of_properties.game_stage = 'ongoing_game'

            end

            if global.table_of_properties.game_stage == 'check_the_number_of_players_who_want_to_fight' then

                local number_of_players = 0

                for _, player in pairs( global.table_of_players ) do

                    if not player.is_spectator then number_of_players = number_of_players + 1 end

                end

                if number_of_players > 1 then

                    global.table_of_properties.game_stage = 'send_the_players_into_the_arena_fully_armed_with_a_tank'

                end

            end

            if global.table_of_properties.game_stage == 'teleport_from_nauvis_to_the_arena' then

                local surface = game.surfaces.tank_battles

                local position = { x = 0, y = 0 }

                for _, player in pairs( game.connected_players ) do

                    if player.character then

                        player.character.clear_items_inside()

                        player.character.destroy()

                        player.character = nil

                    end

                    player.create_character()

                    if surface.is_chunk_generated( position ) then player.teleport( surface.find_non_colliding_position( 'character', position, 9, 0.5 ), surface ) else player.teleport( position, surface ) end

                end

                global.table_of_properties.game_stage = 'check_the_number_of_players_who_want_to_fight'

            end

            if global.table_of_properties.game_stage == 'preparing_spawn_positions' then

                execute_on_tick( game.tick + 1, draw_circle_lobby, { game.surfaces.tank_battles, 14, { x = 0, y = 0 } } )

                global.table_of_properties.game_stage = 'teleport_from_nauvis_to_the_arena'

            end

            if global.table_of_properties.game_stage == 'check_the_process_of_creating_the_surface' then

                if game.surfaces.tank_battles.is_chunk_generated( { x = 0, y = 0 } ) then

                    global.table_of_properties.game_stage = 'preparing_spawn_positions'

                else

                    game.surfaces.tank_battles.request_to_generate_chunks( { x = 0, y = 0 }, 1 )

                end

            end

            if global.table_of_properties.game_stage == 'regenerate_the_customize_surface' then

                initialize_surface_standard()

                initialize_surface_customize()

                game.surfaces.tank_battles.daytime = 0

                game.surfaces.tank_battles.freeze_daytime = 0

                game.surfaces.tank_battles.force_generate_chunk_requests()

                global.table_of_properties.game_stage = 'check_the_process_of_creating_the_surface'

            end

            if global.table_of_properties.game_stage == 'lobby' then

                global.table_of_properties.game_stage = 'regenerate_the_customize_surface'

            end

        end

        if game.tick % 10800 == 0 and global.table_of_properties.game_stage == 'ongoing_game' then

            for _, player in pairs( game.connected_players ) do

                local player_properties = global.table_of_players[ player.index ]

                if player_properties.in_battle then launch_atomic_rocket( player ) end

            end

        end

        if game.tick % global.table_of_properties.circle_interval == 0 and global.table_of_properties.game_stage == 'ongoing_game' then do_shrink_circle() end

    end

    event.add( defines.events.on_tick, on_tick )

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        if not global.table_of_players[ player.index ] then global.table_of_players[ player.index ] = { won_rounds = 0, player_killed = 0, in_battle = false, is_spectator = false, tank = nil, spawn = nil } end

        if not game.forces[ 'force_player_' .. player.index ] then

            game.create_force( 'force_player_' .. player.index )

            local force = game.forces[ 'force_player_' .. player.index ]

            force.set_friend( 'force_spectator', true )

            force.technologies[ 'follower-robot-count-1' ].researched = true

            force.technologies[ 'toolbelt' ].researched = true

            force.research_queue_enabled = true

            force.friendly_fire = false

            force.share_chart = false

        end

        game.permissions.get_group( 'permission_spectator' ).add_player( player )

        player.force = game.forces.force_spectator

        player.character.destructible = false

        player.minimap_enabled = false

        player.game_view_settings = { show_controller_gui = true, show_minimap = false, show_research_info = false, show_entity_info = true, show_alert_gui = true, update_entity_selection = true, show_rail_block_visualisation = false, show_side_menu = false, show_map_view_options = false, show_quickbar = true, show_shortcut_bar = false }

        local surface = game.surfaces.nauvis

        if global.table_of_properties.game_stage == 'ongoing_game' then surface = game.surfaces.tank_battles end

        if surface.is_chunk_generated( { x = 0, y = 0 } ) then player.teleport( surface.find_non_colliding_position( 'character', { x = 0, y = 0 }, 9, 0.5 ), surface ) else player.teleport( { x = 0, y = 0 }, surface ) end

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )

    local function on_player_respawned( event )

        local player = game.players[ event.player_index ]

        game.permissions.get_group( 'permission_spectator' ).add_player( player )

        player.force = game.forces.force_spectator

        player.character.destructible = false

        local surface = game.surfaces.nauvis

        if global.table_of_properties.game_stage == 'ongoing_game' then surface = game.surfaces.tank_battles end

        if surface.is_chunk_generated( { x = 0, y = 0 } ) then player.teleport( surface.find_non_colliding_position( 'character', { x = 0, y = 0 }, 9, 0.5 ), surface ) else player.teleport( { x = 0, y = 0 }, surface ) end

    end

    event.add( defines.events.on_player_respawned, on_player_respawned )

    local function on_player_died( event )

        local player = game.players[ event.player_index ]

        local player_properties = global.table_of_players[ player.index ]

        player.ticks_to_respawn = 180

        player_properties.in_battle = false

        local table_of_entities = player.surface.find_entities_filtered( { name = 'character-corpse' } )

        for _, entity in pairs( table_of_entities ) do

            entity.clear_items_inside()

            entity.destroy()

        end

        if player_properties.tank ~= nil and player_properties.tank.valid then

            player_properties.tank.clear_items_inside()

            player_properties.tank.destroy()

        end

        player_properties.tank = nil

        local player_name_of_the_causer = nil

        local player_death_message = player.name .. ' was killed.'

        if event.cause and event.cause.valid then

            if event.cause.name == 'character' then

                local player_properties = global.table_of_players[ event.cause.player.index ]

                player_properties.player_killed = player_properties.player_killed + 1

                player_name_of_the_causer = event.cause.player.name

                player_death_message = player.name .. ' was killed by the player ' .. event.cause.player.name .. '.'

                -- return -- Killing by a player is displayed twice.

            elseif event.cause.name == 'car' or event.cause.name == 'tank' or event.cause.name == 'train' then

                local driver = event.cause.get_driver()

                if driver.player then

                    local player_properties = global.table_of_players[ driver.player.index ]

                    player_properties.player_killed = player_properties.player_killed + 1

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

    event.add( defines.events.on_player_died, on_player_died )

    local function on_player_left_game( event )

        local player = game.players[ event.player_index ]

        local player_properties = global.table_of_players[ player.index ]

        if game.forces[ 'force_player_' .. player.index ] then game.forces[ 'force_player_' .. player.index ] = nil end

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        if player_properties.tank ~= nil and player_properties.tank.valid then

            player_properties.tank.clear_items_inside()

            player_properties.tank.destroy()

        end

        if player_properties.tank then player_properties.tank = nil end

        if player_properties then player_properties = nil end

    end

    event.add( defines.events.on_player_left_game, on_player_left_game )

    local function on_chunk_generated( event )

        if event.surface.name == 'nauvis' then return end

        if not global.table_of_properties.noise_seed then global.table_of_properties.noise_seed = math_random( 1, 2097152 ) end

        local chunk_position = { x = event.area.left_top.x, y = event.area.left_top.y }

        for x = 0, 31 do for y = 0, 31 do

            local tile_position = { x = chunk_position.x + x, y = chunk_position.y + y }

            entity_to_arena( event.surface, tile_position )

        end end

    end

    event.add( defines.events.on_chunk_generated, on_chunk_generated )

    local function on_chunk_charted( event )

        if event.force.name == 'force_spectator' then return end

        event.force.clear_chart()

    end

    event.add( defines.events.on_chunk_charted, on_chunk_charted )

    local function on_marked_for_deconstruction( event )

        event.entity.cancel_deconstruction( game.players[ event.player_index ].force.name )

    end

    event.add( defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction )

    require 'maps.tank_conquest.module_loot_boxes'

    require 'maps.tank_conquest.module_player_belt'

    require 'maps.tank_battles.module_player_settings'

    require 'maps.tank_battles.module_player_scoreboard'
