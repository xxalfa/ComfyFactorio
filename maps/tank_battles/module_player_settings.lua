
    local event = require 'utils.event'

    local gui = require 'utils.gui'

    local name_headline_button = gui.uid_name()

    local name_main_frame = gui.uid_name()

    local name_main_button_close = gui.uid_name()

    local name_main_button_submit = gui.uid_name()

    local question_string = ''

    local function draw_headline_button( player )

        if player.gui.top[ name_headline_button ] then player.gui.top[ name_headline_button ].destroy() end

        local element_button = player.gui.top.add( { type = 'button', name = name_headline_button, caption = 'SETTINGS', tooltip = '' } )

        element_button.style.height = 38

    end

    local function draw_main_frame( player )

        if player.gui.center[ name_main_frame ] then player.gui.center[ name_main_frame ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = name_main_frame, caption = 'Settings', direction = 'vertical' } )

        if global.table_of_players[ player.index ].is_spectator then

            question_string = 'Join the battle again?'

        else

            question_string = 'Would like to be a spectator?'

        end

        local element_label = element_frame.add( { type = 'label', caption = question_string } )

        element_label.style.font = 'compi'

        element_label.style.top_padding = 5

        element_label.style.bottom_padding = 5

        element_label.style.horizontal_align = 'center'

        element_label.style.horizontally_stretchable = true

        element_label.style.font_color = { r = 1, g = 1, b = 1 }

        local element_flow = element_frame.add( { type = 'flow' } )

        element_flow.style.horizontal_align = 'center'

        element_flow.style.horizontally_stretchable = true

        local element_button = element_flow.add( { type = 'button', name = name_main_button_submit, style = 'rounded_button', caption = 'SUBMIT' } )

        element_button.style.minimal_width = 150

        local element_label = element_flow.add( { type = 'label' } )

        element_label.style.minimal_width = 170

        local element_button = element_flow.add( { type = 'button', name = name_main_button_close, style = 'rounded_button', caption = 'CLOSE' } )

        element_button.style.minimal_width = 150

    end

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

        if event.element.valid and event.element.name == name_main_button_submit then

            if global.table_of_players[ player.index ].is_spectator then

                global.table_of_players[ player.index ].is_spectator = false

                player.print( 'In the next round you will be part of the battle again.', player.chat_color )

            else

                global.table_of_players[ player.index ].is_spectator = true

                player.print( 'You are now spectating.', player.chat_color )

                event_on_click_lobby( player )

            end

            player.gui.center[ name_main_frame ].visible = false

        end

        if event.element.valid and event.element.name == name_main_button_close then

            player.gui.center[ name_main_frame ].visible = false

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        draw_headline_button( player )

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )
