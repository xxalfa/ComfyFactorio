
    local event = require 'utils.event'

    local gui = require 'utils.gui'

    local name_headline_button = gui.uid_name()

    local name_main_frame = gui.uid_name()

    local name_main_button_close = gui.uid_name()

    local name_camera_frame = gui.uid_name()

    local name_camera_observation = gui.uid_name()

    local name_camera_button_close = gui.uid_name();

    local table_of_observations = {}

    local function draw_headline_button( player )

        if player.gui.top[ name_headline_button ] then player.gui.top[ name_headline_button ].destroy() end

        local element_button = player.gui.top.add( { type = 'button', name = name_headline_button, caption = 'SCOREBOARD', tooltip = '' } )

        element_button.style.height = 38

    end

    local function draw_main_frame( player )

        if player.gui.center[ name_main_frame ] then player.gui.center[ name_main_frame ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = name_main_frame, caption = 'Scoreboard', direction = 'vertical' } )

        local element_table = element_frame.add( { type = 'table', column_count = 7, draw_horizontal_lines = true } )

        element_table.style.padding = 0

        element_table.style.margin = 0

        element_table.style.top_margin = 10

        element_table.style.vertical_align = 'center'

        element_table.style.horizontal_align = 'center'

        element_table.add( { type = 'label', caption = '#' } )

        element_table.add( { type = 'label', caption = 'Name' } )

        element_table.add( { type = 'label', caption = 'Won rounds' } )

        element_table.add( { type = 'label', caption = 'Player killed' } )

        element_table.add( { type = 'label', caption = 'In battle' } )

        element_table.add( { type = 'label', caption = 'Is spectator' } )

        element_table.add( { type = 'label', caption = '' } )

        local table_of_scores = {}

        for _, player in pairs( game.connected_players ) do

            local player_properties = global.table_of_players[ player.index ]

            local color = game.players[ player.index ].color

            color = { r = color.r * 0.6 + 0.4, g = color.g * 0.6 + 0.4, b = color.b * 0.6 + 0.4, a = 1 }

            table.insert( table_of_scores, { index = player.index, name = player.name, won_rounds = player_properties.won_rounds, player_killed = player_properties.player_killed, in_battle = player_properties.in_battle, is_spectator = player_properties.is_spectator, color = color } )

        end

        local number_of_scores = #table_of_scores

        for index = 1, number_of_scores do

            if not table_of_scores[ index + 1 ] then break end

            if table_of_scores[ index ].won_rounds < table_of_scores[ index + 1 ].won_rounds then

                local key = table_of_scores[ index ]

                table_of_scores[ index ] = table_of_scores[ index + 1 ]

                table_of_scores[ index + 1 ] = key

            end

        end

        for index = 1, number_of_scores do

            element_table.add( { type = 'label', caption = index } )

            local element_label = element_table.add( { type = 'label', caption = table_of_scores[ index ].name } )

            element_label.style.font_color = table_of_scores[ index ].color

            element_table.add( { type = 'label', caption = table_of_scores[ index ].won_rounds } )

            element_table.add( { type = 'label', caption = table_of_scores[ index ].player_killed } )

            local label_caption = ''

            if table_of_scores[ index ].in_battle then label_caption = 'yes' else label_caption = 'no' end

            element_table.add( { type = 'label', caption = label_caption } )

            if table_of_scores[ index ].is_spectator then label_caption = 'yes' else label_caption = 'no' end

            element_table.add( { type = 'label', caption = label_caption } )

            local element_button = element_table.add( { type = 'button', name = 'observe_player_' .. table_of_scores[ index ].index, caption = 'OBSERVE' } )

            element_button.style.height = 18

        end

        for _, element_item in pairs( element_table.children ) do

            element_item.style.minimal_width = 100

            element_item.style.padding = 0

            element_item.style.margin = 0

            element_item.style.vertical_align = 'center'

            element_item.style.horizontal_align = 'center'

            element_item.style.font = 'default-tiny-bold'

        end

        local element_flow = element_frame.add( { type = 'flow' } )

        element_flow.style.top_margin = 15

        element_flow.style.horizontal_align = 'right'

        element_flow.style.horizontally_stretchable = true

        element_flow.add( { type = 'button', name = name_main_button_close, style = 'rounded_button', caption = 'CLOSE' } )

    end

    local function draw_camera_observation_frame( supervisor_index, player_index )

        local supervisor = game.players[ supervisor_index ]

        local player = game.players[ player_index ]

        if supervisor.gui.center[ name_camera_frame ] then supervisor.gui.center[ name_camera_frame ].destroy() end

        local element_frame = supervisor.gui.center.add( { type = 'frame', name = name_camera_frame, direction = 'vertical' } )

        element_frame.style.padding = 0

        local element_camera = element_frame.add( { type = 'camera', name = name_camera_observation, position = player.position, zoom = 0.3 } )

        element_camera.style.width = 832

        element_camera.style.height = 624

        local element_flow = element_frame.add( { type = 'flow' } )

        element_flow.style.horizontal_align = 'right'

        element_flow.style.horizontally_stretchable = true

        element_flow.add( { type = 'button', name = name_camera_button_close, style = 'rounded_button', caption = 'CLOSE' } )

        if not table_of_observations[ supervisor_index ] then table_of_observations[ supervisor_index ] = player_index end

    end

    local function on_tick( event )

        if global.game_stage ~= 'ongoing_game' then return end

        for supervisor_index, player_index in pairs( table_of_observations ) do

            local supervisor = game.players[ supervisor_index ]

            local player = game.players[ player_index ]

            if supervisor.gui.center[ name_camera_frame ] then supervisor.gui.center[ name_camera_frame ].children[ 1 ].position = player.position end

        end

    end

    event.add( defines.events.on_tick, on_tick )

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        if event.element.valid and event.element.name == name_headline_button then

            if player.gui.center[ name_main_frame ] then

                -- if player.gui.center[ name_main_frame ].visible == true then

                --     player.gui.center[ name_main_frame ].visible = false

                -- else

                --     player.gui.center[ name_main_frame ].visible = true

                -- end

                player.gui.center[ name_main_frame ].destroy()

            else

                draw_main_frame( player )

            end

        end

        if event.element.valid and event.element.name == name_main_button_close then

            player.gui.center[ name_main_frame ].visible = false

        end

        if string.sub( event.element.name, 1, 14 ) == 'observe_player' then

            if global.game_stage == 'ongoing_game' then

                if player.force.name == 'force_spectator' then

                    local observe_player_index = string.sub( event.element.name, 16, string.len( event.element.name ) )

                    if player.index ~= tonumber( observe_player_index ) then

                        player.gui.center[ name_main_frame ].visible = false

                        draw_camera_observation_frame( player.index, observe_player_index )

                    else

                        player.print( 'Wanting to watch yourself sounds nice, but it does not make sense.' )

                    end

                else

                    player.print( 'It borders on cheating while you are still in battle to want to watch someone else.' )

                end

            else

                player.print( 'If you want to watch, nothing is going on right now.' )

            end

        end

        if event.element.valid and event.element.name == name_camera_button_close then

            hide_gui_player_camera( player )

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        draw_headline_button( player )

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )

    local function on_player_left_game( event )

        if table_of_observations[ event.player_index ] then table_of_observations[ event.player_index ] = nil end

    end

    event.add( defines.events.on_player_left_game, on_player_left_game )

    function show_gui_player_scoreboard( player )

        draw_main_frame( player )

    end

    function hide_gui_player_scoreboard( player )

        if player.gui.center[ name_main_frame ] then player.gui.center[ name_main_frame ].destroy() end

    end

    function hide_gui_player_camera( player )

        if player.gui.center[ name_main_frame ] then player.gui.center[ name_camera_frame ].visible = false end

        if table_of_observations[ player.index ] then table_of_observations[ player.index ] = nil end

    end
