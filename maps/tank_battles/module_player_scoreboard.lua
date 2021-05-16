
    global.game_players_camera = {}

    local utils_gui = require 'utils.gui'

    local name_headline_button = utils_gui.uid_name()

    local name_main_frame = utils_gui.uid_name()

    local name_main_button_close = utils_gui.uid_name()

    local name_camera_frame = utils_gui.uid_name()

    local name_camera_observation = utils_gui.uid_name()

    local name_camera_button_close = utils_gui.uid_name();

    local function on_tick()

        if global.game_stage ~= 'ongoing_game' then return end

        for supervisor_index, player_index in pairs( global.game_players_camera ) do

            local supervisor = game.players[ supervisor_index ]

            local player = game.players[ player_index ]

            if supervisor.gui.center[ name_camera_frame ] then supervisor.gui.center[ name_camera_frame ].children[ 1 ].position = player.position end

        end

    end

    local function draw_main_frame( player )

        if player.gui.center[ name_main_frame ] then player.gui.center[ name_main_frame ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = name_main_frame, caption = 'Scoreboard', direction = 'vertical' } )

        local element_table = element_frame.add( { type = 'table', column_count = 8, draw_horizontal_lines = true } )

        element_table.style.padding = 0

        element_table.style.margin = 0

        element_table.style.top_margin = 10

        element_table.style.vertical_align = 'center'

        element_table.style.horizontal_align = 'center'

        element_table.add( { type = 'label', caption = '#' } )

        element_table.add( { type = 'label', caption = '[entity=character]', tooltip = 'NAME' } )

        element_table.add( { type = 'label', caption = '' } )

        element_table.add( { type = 'label', caption = '[item=tank]', tooltip = 'WON ROUNDS' } )

        element_table.add( { type = 'label', caption = '[img=utility/shoot_cursor_red]', tooltip = 'PLAYER KILLED' } )

        element_table.add( { type = 'label', caption = '[entity=wooden-chest-remnants]', tooltip = 'BOXES LOOTED' } )

        element_table.add( { type = 'label', caption = '[item=cannon-shell]', tooltip = 'DAMAGE CAUSED' } )

        element_table.add( { type = 'label', caption = '' } )

        local table_of_scores = {}

        for _, player_item in pairs( game.connected_players ) do

            local player_memory = global.game_players_memory[ player_item.index ]

            local color = game.players[ player_item.index ].color

            color = { r = color.r * 0.6 + 0.4, g = color.g * 0.6 + 0.4, b = color.b * 0.6 + 0.4, a = 1 }

            table.insert( table_of_scores, { index = player_item.index, color = color, name = player_item.name, in_battle = player_memory.in_battle, is_spectator = player_memory.is_spectator, won_rounds = player_memory.won_rounds, player_killed = player_memory.player_killed, boxes_looted = player_memory.boxes_looted, damage_caused = player_memory.damage_caused } )

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

            local label_caption = '[color=red]☠[/color]'

            local label_tooltip = 'IS DEAD'

            if table_of_scores[ index ].in_battle then label_caption = '[item=pistol]' end

            if table_of_scores[ index ].in_battle then label_tooltip = 'IN BATTLE' end

            if table_of_scores[ index ].is_spectator then label_caption = '[item=night-vision-equipment]' end

            if table_of_scores[ index ].is_spectator then label_tooltip = 'IS SPECTATOR' end

            element_table.add( { type = 'label', caption = label_caption, tooltip = label_tooltip } )

            element_table.add( { type = 'label', caption = table_of_scores[ index ].won_rounds } )

            element_table.add( { type = 'label', caption = table_of_scores[ index ].player_killed } )

            element_table.add( { type = 'label', caption = table_of_scores[ index ].boxes_looted } )

            element_table.add( { type = 'label', caption = '[color=1,0,1]' ..  math.ceil( table_of_scores[ index ].damage_caused ) .. '[/color]' } )

            local element_button = element_table.add( { type = 'button', name = 'observe_player_' .. table_of_scores[ index ].index, caption = 'OBSERVE' } )

            element_button.style.height = 18

        end

        for _, element_item in pairs( element_table.children ) do

            element_item.style.minimal_width = 80

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

        if not global.game_players_camera[ supervisor_index ] then global.game_players_camera[ supervisor_index ] = player_index end

    end

    local function on_gui_click( event )

        if not event.element.valid then return end

        local player = game.players[ event.player_index ]

        if event.element.name == name_headline_button then

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

        if event.element.name == name_main_button_close then player.gui.center[ name_main_frame ].visible = false end

        if string.sub( event.element.name, 1, 14 ) == 'observe_player' then

            if global.game_stage == 'ongoing_game' then

                if player.force.name == 'force_spectator' then

                    local observe_player_index = string.sub( event.element.name, 16, string.len( event.element.name ) )

                    if player.index ~= tonumber( observe_player_index ) then

                        hide_gui_player_scoreboard( player )

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

        if event.element.name == name_camera_button_close then

            hide_gui_player_camera( player )

            show_gui_player_scoreboard( player )

        end

    end

    local function draw_headline_button( player )

        if player.gui.top[ name_headline_button ] then player.gui.top[ name_headline_button ].destroy() end

        local element_button = player.gui.top.add( { type = 'button', name = name_headline_button, caption = 'SCOREBOARD', tooltip = '' } )

        element_button.style.height = 32

    end

    local function on_player_joined_game( event )

        if global.game_players_camera[ event.player_index ] then global.game_players_camera[ event.player_index ] = {} end

        local player = game.players[ event.player_index ]

        draw_headline_button( player )

    end

    local function on_player_left_game( event )

        if global.game_players_camera[ event.player_index ] then global.game_players_camera[ event.player_index ] = nil end

    end

    function show_gui_player_scoreboard( player )

        draw_main_frame( player )

    end

    function hide_gui_player_scoreboard( player )

        if player.gui.center[ name_main_frame ] then player.gui.center[ name_main_frame ].destroy() end

    end

    function hide_gui_player_camera( player )

        if player.gui.center[ name_camera_frame ] then player.gui.center[ name_camera_frame ].visible = false end

        if global.game_players_camera[ player.index ] then global.game_players_camera[ player.index ] = nil end

    end

    local Event = require 'utils.event'

    Event.add( defines.events.on_player_joined_game, on_player_joined_game )

    Event.add( defines.events.on_gui_click, on_gui_click )

    Event.add( defines.events.on_tick, on_tick )

    Event.add( defines.events.on_player_left_game, on_player_left_game )
