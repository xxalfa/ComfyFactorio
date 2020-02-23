
    local event = require 'utils.event'

    local gui = require 'utils.gui'

    local name_button_headline = gui.uid_name()

    local name_frame_main = gui.uid_name()

    local name_button_close = gui.uid_name()

    local name_button_submit = gui.uid_name()

    local question_string = ''

    local function draw_button_headline( player )

        if player.gui.top[ name_button_headline ] then player.gui.center[ name_button_headline ].destroy() end

        local element_button = player.gui.top.add( { type = 'button', name = name_button_headline, caption = 'SETTINGS', tooltip = '' } )

        element_button.style.height = 38

    end

    local function draw_frame_main( player )

        if player.gui.center[ name_frame_main ] then player.gui.center[ name_frame_main ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = name_frame_main, caption = 'Settings', direction = 'vertical' } )

        local player_properties = global.table_of_players[ player.index ]

        if player_properties.is_spectator then

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

        local element_button = element_flow.add( { type = 'button', name = name_button_submit, style = 'rounded_button', caption = 'SUBMIT' } )

        element_button.style.minimal_width = 150

        local element_label = element_flow.add( { type = 'label' } )

        element_label.style.minimal_width = 170

        local element_button = element_flow.add( { type = 'button', name = name_button_close, style = 'rounded_button', caption = 'CLOSE' } )

        element_button.style.minimal_width = 150

    end

    local function on_init( event )

        game.create_force( 'force_spectator' )

        local force = game.forces.force_spectator

        force.set_cease_fire( 'enemy', true )

        force.friendly_fire = false

        force.share_chart = true

        local force = game.forces.enemy

        force.set_cease_fire( 'force_spectator', true )

    end

    event.on_init( on_init )

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        local player_properties = global.table_of_players[ player.index ]

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

            if player_properties.is_spectator then

                player_properties.is_spectator = false

                player.print( 'In the next round you will be part of the battle again.', { r = 255, g = 127, b = 80 } )

            else

                player_properties.is_spectator = true

                player.print( 'You are now spectating.', { r = 255, g = 127, b = 80 } )

                player.character.die()

            end

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

    local function on_player_left_game( event )

        local player = game.players[ event.player_index ]

    end

    event.add( defines.events.on_player_left_game, on_player_left_game )

