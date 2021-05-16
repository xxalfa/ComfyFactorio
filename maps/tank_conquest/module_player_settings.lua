
    local utils_gui = require 'utils.gui'

    local name_headline_button = utils_gui.uid_name()

    local name_main_frame = utils_gui.uid_name()

    local name_main_button_close = utils_gui.uid_name()

    local name_main_button_submit = utils_gui.uid_name()

    local function draw_main_frame( player )

        if player.gui.center[ name_main_frame ] then player.gui.center[ name_main_frame ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = name_main_frame, caption = 'Settings', direction = 'vertical' } )

        local element_label = element_frame.add( { type = 'label', caption = 'EMPTY' } )

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

        element_label = element_flow.add( { type = 'label' } )

        element_label.style.minimal_width = 170

        element_button = element_flow.add( { type = 'button', name = name_main_button_close, style = 'rounded_button', caption = 'CLOSE' } )

        element_button.style.minimal_width = 150

    end

    local function on_gui_click( event )

        if not event.element.valid then return end

        local player = game.players[ event.player_index ]

        if event.element.name == name_headline_button then

            if player.gui.center[ name_main_frame ] then

                if player.gui.center[ name_main_frame ].visible == true then

                    player.gui.center[ name_main_frame ].visible = false

                else

                    player.gui.center[ name_main_frame ].visible = true

                end

            else

                draw_main_frame( player )

            end

        end

        if event.element.name == name_main_button_submit then player.gui.center[ name_main_frame ].visible = false end

        if event.element.name == name_main_button_close then player.gui.center[ name_main_frame ].visible = false end

    end

    local function draw_headline_button( player )

        if player.gui.top[ name_headline_button ] then player.gui.top[ name_headline_button ].destroy() end

        local element_button = player.gui.top.add( { type = 'button', name = name_headline_button, caption = 'SETTINGS', tooltip = '' } )

        element_button.style.height = 32

    end

    local function on_player_joined_game( event )

        if not global.game_players_memory[ event.player_index ] then global.game_players_memory[ event.player_index ] = {} end

        local player = game.players[ event.player_index ]

        draw_headline_button( player )

    end

    -- local function on_player_left_game( event )

    --     if global.game_players_memory[ event.player_index ].some_setting then global.game_players_memory[ event.player_index ].some_setting = nil end

    -- end

    local Event = require 'utils.event'

    Event.add( defines.events.on_player_joined_game, on_player_joined_game )

    Event.add( defines.events.on_gui_click, on_gui_click )

    -- Event.add( defines.events.on_player_left_game, on_player_left_game )
