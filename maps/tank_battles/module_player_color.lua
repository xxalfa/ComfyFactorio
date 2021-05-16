
    -- local Schedule = require 'maps.tank_battles.on_tick_schedule'

    require 'maps.tank_battles.on_tick_schedule'

    local table_of_colored_tiles = {}

    table_of_colored_tiles[ 1 ] = { color_name = 'white', tile_name = 'refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 1, g = 1, b = 1, a = 0.5 }, chat_color = { r = 1, g = 1, b = 1 }  }

    table_of_colored_tiles[ 2 ] = { color_name = 'yellow', tile_name = 'yellow-refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 0.835, g = 0.666, b = 0.077, a = 0.5 }, chat_color = { r = 1, g = 0.828, b = 0.231 } }

    table_of_colored_tiles[ 3 ] = { color_name = 'orange', tile_name = 'orange-refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 0.869, g = 0.5, b = 0.130, a = 0.5 }, chat_color = { r = 1, g = 0.630, b = 0.259 } }

    table_of_colored_tiles[ 4 ] = { color_name = 'red', tile_name = 'red-refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 0.815, g = 0.024, b = 0, a = 0.5 }, chat_color = { r = 1, g = 0.266, b = 0.241 } }

    table_of_colored_tiles[ 5 ] = { color_name = 'acid', tile_name = 'acid-refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 0.559, g = 0.761, b = 0.157, a = 0.5 }, chat_color = { r = 0.708, g = 0.996, b = 0.134 } }

    table_of_colored_tiles[ 6 ] = { color_name = 'green', tile_name = 'green-refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 0.093, g = 0.768, b = 0.172, a = 0.5 }, chat_color = { r = 0.173, g = 0.824, b = 0.250 } }

    table_of_colored_tiles[ 7 ] = { color_name = 'cyan', tile_name = 'cyan-refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 0.275, g = 0.755, b = 0.712, a = 0.5 }, chat_color = { r = 0.335, g = 0.918, b = 0.866 } }

    table_of_colored_tiles[ 8 ] = { color_name = 'blue', tile_name = 'blue-refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 0.155, g = 0.540, b = 0.898, a = 0.5 }, chat_color = { r = 0.343, g = 0.683, b = 1 } }

    table_of_colored_tiles[ 9 ] = { color_name = 'pink', tile_name = 'pink-refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 0.929, g = 0.386, b = 0.514, a = 0.5 }, chat_color = { r = 1, g = 0.720, b = 0.833 } }

    table_of_colored_tiles[ 10 ] = { color_name = 'purple', tile_name = 'purple-refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 0.485, g = 0.111, b = 0.659, a = 0.5 }, chat_color = { r = 0.821, g = 0.440, b = 0.998 } }

    table_of_colored_tiles[ 11 ] = { color_name = 'brown', tile_name = 'brown-refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 0.300, g = 0.117, b = 0, a = 0.5 }, chat_color = { r = 0.757, g = 0.522, b = 0.371 } }

    table_of_colored_tiles[ 12 ] = { color_name = 'black', tile_name = 'black-refined-concrete', position = { x = 1, y = 1 }, player_color = { r = 0.1, g = 0.1, b = 0.1, a = 0.5 }, chat_color = { r = 0.5, g = 0.5, b = 0.5 } }

    local function draw_a_circle_of_colored_dots()

        local circle_position = { x = 0.5, y = 0.5 }

        local distance = 6.5

        local angle = 0

        local sides = #table_of_colored_tiles

        local factor = math.pi / sides

        local table_of_positions = {}

        for index = 1, sides do

            local x = circle_position.x + math.cos( angle + ( index + index - 1 ) * factor ) * distance

            local y = circle_position.y + math.sin( angle + ( index + index - 1 ) * factor ) * distance

            table.insert( table_of_positions, { x = math.floor( x ), y = math.floor( y ) } )

        end

        local table_of_tiles = {}

        for index, position in pairs( table_of_positions ) do

            table_of_colored_tiles[ index ].position = position

            table.insert( table_of_tiles, { name = table_of_colored_tiles[ index ].tile_name, position = position } )

        end

        game.surfaces.nauvis.set_tiles( table_of_tiles, true )

    end

    local function on_player_joined_game( event )

        local index = 1

        local player = game.players[ event.player_index ]

        player.color = table_of_colored_tiles[ index ].player_color

        player.chat_color = table_of_colored_tiles[ index ].chat_color

        if not global.game_players_memory[ event.player_index ] then global.game_players_memory[ event.player_index ] = {} end

        if not global.game_players_memory[ event.player_index ].selected_color then global.game_players_memory[ event.player_index ].selected_color = table_of_colored_tiles[ index ].color_name end

        if not global.is_the_circle_drawn_of_colored_dots then

            schedule_execute_on_tick( game.tick + 2, draw_a_circle_of_colored_dots, { x = 0, y = 0 } )

            global.is_the_circle_drawn_of_colored_dots = true

        end

    end

    local function on_player_changed_position( event )

        local player = game.players[ event.player_index ]

        if player.surface.name ~= 'nauvis' then return end

        for index, item in pairs( table_of_colored_tiles ) do

            if global.game_players_memory[ player.index ].selected_color ~= item.color_name then

                if math.floor( player.position.x ) == item.position.x and math.floor( player.position.y ) == item.position.y then

                    player.color = item.player_color

                    player.chat_color = item.chat_color

                    global.game_players_memory[ player.index ].selected_color = item.color_name

                    return

                end

            end

        end

    end

    local function on_player_left_game( event )

        if global.game_players_memory[ event.player_index ].selected_color then global.game_players_memory[ event.player_index ].selected_color = nil end

    end

    local Event = require 'utils.event'

    Event.add( defines.events.on_player_joined_game, on_player_joined_game )

    Event.add( defines.events.on_player_changed_position, on_player_changed_position )

    Event.add( defines.events.on_player_left_game, on_player_left_game )
