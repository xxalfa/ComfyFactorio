
    local event = require 'utils.event'

    local gui = require 'utils.gui'

    local name_button_headline = gui.uid_name()

    local name_frame_main = gui.uid_name()

    local name_button_close = gui.uid_name()

    local name_button_submit = gui.uid_name()

    local function draw_button_headline( player )

        if player.gui.top[ name_button_headline ] then return end

        local element_button = player.gui.top.add( { type = 'button', name = name_button_headline, caption = 'SCOREBOARD', tooltip = '' } )

        element_button.style.height = 38

    end

    local function draw_frame_main( player )

        if player.gui.center[ name_frame_main ] then player.gui.center[ name_frame_main ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = name_frame_main, caption = 'Scoreboard', direction = 'vertical' } )

        local element_table = element_frame.add( { type = 'table', column_count = 6, draw_horizontal_lines = true } )

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

        local table_of_scores = {}

        for _, player in pairs( game.connected_players ) do

            local player_properties = global.table_of_players[ player.index ]

            local color = game.players[ player.index ].color

            color = { r = color.r * 0.6 + 0.4, g = color.g * 0.6 + 0.4, b = color.b * 0.6 + 0.4, a = 1 }

            table.insert( table_of_scores, { name = player.name, won_rounds = player_properties.won_rounds, player_killed = player_properties.player_killed, in_battle = player_properties.in_battle, is_spectator = player_properties.is_spectator, color = color } )

        end

        for index = 1, #table_of_scores do

            if not table_of_scores[ index + 1 ] then break end

            if table_of_scores[ index ].won_rounds < table_of_scores[ index + 1 ].won_rounds then

                local key = table_of_scores[ index ]

                table_of_scores[ index ] = table_of_scores[ index + 1 ]

                table_of_scores[ index + 1 ] = key

            end

        end

        for index = 1, #table_of_scores do

            element_table.add( { type = 'label', caption = index } )

            local element_label = element_table.add( { type = 'label', caption = table_of_scores[ index ].name } )

            element_label.style.font_color = table_of_scores[ index ].color

            element_table.add( { type = 'label', caption = table_of_scores[ index ].won_rounds } )

            element_table.add( { type = 'label', caption = table_of_scores[ index ].player_killed } )

            element_table.add( { type = 'label', caption = table_of_scores[ index ].in_battle } )

            element_table.add( { type = 'label', caption = table_of_scores[ index ].is_spectator } )

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

        element_flow.add( { type = 'button', name = name_button_close, style = 'rounded_button', caption = 'CLOSE' } )

    end

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        if event.element.valid and event.element.name == name_button_headline then

            if player.gui.center[ name_frame_main ] then

                -- if player.gui.center[ name_frame_main ].visible == true then

                --     player.gui.center[ name_frame_main ].visible = false

                -- else

                --     player.gui.center[ name_frame_main ].visible = true

                -- end

                player.gui.center[ name_frame_main ].destroy()

            else

                draw_frame_main( player )

            end

        end

        if event.element.valid and event.element.name == name_button_submit then

            player.gui.center[ name_frame_main ].visible = false

        end

        if event.element.valid and event.element.name == name_button_close then

            player.gui.center[ name_frame_main ].visible = false

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        draw_button_headline( player )

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )

    function draw_gui_player_scoreboard( player )

        draw_frame_main( player )

    end
