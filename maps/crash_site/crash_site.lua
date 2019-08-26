
    -- factorio scenario -- crash site -- sebber26 and xalpha made this --

    global.table_of_properties = {}

    global.table_of_settings = {}

    global.table_of_ores = { 'iron-ore', 'copper-ore', 'stone', 'coal' }

    local map_functions = require 'tools.map_functions'

    local event = require 'utils.event'

    local map_intro = [[ - - - C R A S H   S I T E - - - ]]

    local function draw_gui_intro_button( player )

        if player.gui.top[ 'draw_gui_intro_button' ] then return end

        local element_button = player.gui.top.add( { type = 'sprite-button', name = 'draw_gui_intro_button', caption = '?', tooltip = 'INTRO' } )

        element_button.style.width = 38

        element_button.style.height = 38

        element_button.style.font_color = { r = 0.5, g = 0.3, b = 0.99 }

        element_button.style.font = 'heading-1'

    end

    local function draw_gui_intro_frame( player )

        if player.gui.center[ 'draw_gui_intro_frame' ] then player.gui.center[ 'draw_gui_intro_frame' ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = 'draw_gui_intro_frame', direction = 'vertical' } )

        element_frame = element_frame.add( { type = 'frame' } )

        local element_label = element_frame.add( { type = 'label', name = 'draw_gui_intro_content', caption = map_intro } )

        element_label.style.top_padding = 15

        element_label.style.single_line = false

        element_label.style.font = 'heading-2'

        element_label.style.font_color = { r = 0.7, g = 0.6, b = 0.99 }

    end

    local function initialize_forces()

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.grab_blueprint_record, false )

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.import_blueprint_string, false )

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.import_blueprint, false )

    end

    function initialize_surface()

        game.map_settings.enemy_evolution.time_factor = 0

        game.map_settings.enemy_evolution.destroy_factor = 0

        game.map_settings.enemy_evolution.pollution_factor = 0

        game.map_settings.pollution.enabled = false

        game.map_settings.enemy_expansion.enabled = true

        game.map_settings.enemy_expansion.settler_group_min_size = 8

        game.map_settings.enemy_expansion.settler_group_max_size = 16

        game.map_settings.enemy_expansion.min_expansion_cooldown = 54000

        game.map_settings.enemy_expansion.max_expansion_cooldown = 108000

        local map_gen_settings = {}

        map_gen_settings.width = global.table_of_properties.size_of_the_battlefield

        map_gen_settings.height = global.table_of_properties.size_of_the_battlefield

        map_gen_settings.seed = math.random( 1, 2097152 )

        map_gen_settings.water = 'none'

        map_gen_settings.starting_area = 'none'

        map_gen_settings.cliff_settings = { name = 'cliff', cliff_elevation_0 = 0, cliff_elevation_interval = 0 }

        map_gen_settings.autoplace_controls = { [ 'trees' ] = { frequency = 'normal', size = 'normal', richness = 'normal' }, [ 'coal' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'stone' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'copper-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'uranium-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'iron-ore' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'crude-oil' ] = { frequency = 'very-high', size = 'very-low', richness = 'normal' }, [ 'enemy-base' ] = { frequency = 'normal', size = 'normal', richness = 'normal' } }

        -- map_gen_settings.autoplace_settings = { entity = { treat_missing_as_default = false, settings = { frequency = 'none', size = 'none', richness = 'none' } }, decorative = { treat_missing_as_default = false, settings = { frequency = 'none', size = 'none', richness = 'none' } } }

        -- map_gen_settings.default_enable_all_autoplace_controls = false

        if game.surfaces.crash_site == nil then

            game.create_surface( 'crash_site', map_gen_settings )

        else

            rendering.clear()

            game.surfaces.crash_site.clear()

            game.surfaces.crash_site.map_gen_settings = map_gen_settings

         end

    end

    function create_a_point_of_interest( poi_blueprint, poi_position )

        local surface = game.surfaces.crash_site

        local table_of_items = game.json_to_table( poi_blueprint )

        for _, tile in pairs( table_of_items.blueprint.tiles ) do tile.position = { x = tile.position.x + poi_position.x, y = tile.position.y + poi_position.y } end

        surface.set_tiles( table_of_items.blueprint.tiles, true )

        for _, object in pairs( table_of_items.blueprint.entities ) do

            object.force = 'enemy'

            object.position = { x = object.position.x + poi_position.x, y = object.position.y + poi_position.y }

            local entity = surface.create_entity( object )

            if not entity then return end

            if object.name == 'infinity-chest' or object.name == 'substation' or object.name == 'inserter' or object.name == 'accumulator' or object.name == 'solar-panel' then

                entity.destructible = false

                entity.minable = false

                entity.rotatable = false

                entity.operable = false

            end

            if object.name == 'wooden-chest' then

                entity.force = 'neutral'

                entity.destructible = false

                entity.minable = false

                entity.rotatable = false

            end

            if object.name == 'stone-wall' or object.name == 'gate' or object.name == 'land-mine' then entity.minable = false end

        end

    end

    function create_a_safety_cube( surface, force, coordinate, width, height )

        local center = { x = math.floor( width / 2 ), y = math.floor( height / 2 ) }

        local area = { left_top = { x = coordinate.x - center.x, y = coordinate.y - center.y }, right_bottom = { x = coordinate.x + center.x, y = coordinate.y + center.y } }

        for x = area.left_top.x, area.right_bottom.x do for y = area.left_top.y, area.right_bottom.y do

            if x == area.left_top.x or y == area.left_top.y or x == area.right_bottom.x or y == area.right_bottom.y then

                local position = { x = x, y = y }

                for _, entity in pairs( surface.find_entities( { { position.x, position.y }, { position.x + 1, position.y + 1 } } ) ) do entity.destroy() end

                if surface.can_place_entity( { name = 'stone-wall', position = position } ) then

                    local name = 'stone-wall'

                    if y == area.left_top.y + center.y - 1 or y == area.left_top.y + center.y or y == area.left_top.y + center.y + 1 then name = 'gate' end

                    local entity = surface.create_entity( { name = name,  position = position, force = force, create_build_effect_smoke = false } )

                    entity.destructible = false

                    entity.minable = false

                end

            end

        end end

    end

    function shuffle( table_of_items )

        local length_of_items = #table_of_items

            for index = length_of_items, 1, - 1 do

                local random = math.random( length_of_items )

                table_of_items[ index ], table_of_items[ random ] = table_of_items[ random ], table_of_items[ index ]

            end

        return table_of_items

    end

    local function on_init( surface )

        game.surfaces.nauvis.clear()

        game.surfaces.nauvis.map_gen_settings = { width = 1, height = 1 }

        game.create_surface( 'crash_site', { width = 3000, height = 100 } )

        initialize_forces()

        execute_on_tick( game.tick + 60, create_a_safety_cube, { game.surfaces.crash_site, 'player', { x = 0, y = 0 }, 50, 50 } )

    end

    event.on_init( on_init )

    local function on_tick( event )

    end

    event.add( defines.events.on_tick, on_tick )

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        if event.element.valid and event.element.name == 'draw_gui_intro_content' then player.gui.center[ 'draw_gui_intro_frame' ].destroy() return end

        if event.element.valid and event.element.name == 'draw_gui_intro_button' then

            if player.gui.center[ 'draw_gui_intro_frame' ] then player.gui.center[ 'draw_gui_intro_frame' ].destroy() else draw_gui_intro_frame( player ) end

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_console_chat( event )

    end

    event.add( defines.events.on_console_chat, on_console_chat )

    local function on_chunk_generated( event )

    end

    event.add( defines.events.on_chunk_generated, on_chunk_generated )

    local function on_entity_damaged( event )

    end

    event.add( defines.events.on_entity_damaged, on_entity_damaged )

    local function on_entity_died( event )

    end

    event.add( defines.events.on_entity_died, on_entity_died )

    local function on_player_changed_position( event )

        local player = game.players[ event.player_index ]

    end

    event.add( defines.events.on_player_changed_position, on_player_changed_position )

    local function on_player_respawned( event )

        local player = game.players[ event.player_index ]

    end

    event.add( defines.events.on_player_respawned, on_player_respawned )

    local function on_player_died( event )

        local player = game.players[ event.player_index ]

    end

    event.add( defines.events.on_player_died, on_player_died )

    local function on_player_left_game( event )

        local player = game.players[ event.player_index ]

    end

    event.add( defines.events.on_player_left_game, on_player_left_game )

    local function on_player_joined_game( event )

        local surface = game.surfaces.crash_site

        local player = game.players[ event.player_index ]

        draw_gui_intro_button( player )

        if player.online_time == 0 then draw_gui_intro_frame( player ) end

        if not player.character then player.create_character() end

        local position = player.force.get_spawn_position( surface )

        if surface.is_chunk_generated( position ) then player.teleport( surface.find_non_colliding_position( 'character', position, 3, 0.5 ), surface ) else player.teleport( position, surface ) end

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )
