
    local print_override = require 'utils.print_override'

    local utils_gui = require 'utils.gui'

    local max_support_request_length = 1000

    local name_headline_button = utils_gui.uid_name()

    local name_main_frame = utils_gui.uid_name()

    local name_textarea_content = utils_gui.uid_name()

    local name_main_button_submit = utils_gui.uid_name()

    local name_label_counter = utils_gui.uid_name()

    local name_main_button_close = utils_gui.uid_name()

    local function draw_main_frame( player )

        if player.gui.center[ name_main_frame ] then player.gui.center[ name_main_frame ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = name_main_frame, direction = 'vertical' } )

        local element_flow = element_frame.add( { type = 'flow' } )

        element_flow.style.horizontal_align = 'center'

        element_flow.style.horizontally_stretchable = true

        local element_label = element_flow.add( { type = 'label', caption = 'SUPPORT • FEEDBACK • SUGGESTION • REPORT A BUG' } )

        element_label.style.font = 'compi'

        element_label.style.font_color = { r = 1, g = 1, b = 1 }

        local element_textarea = element_frame.add( { type = 'text-box', name = name_textarea_content } )

        element_textarea.style.padding = 5

        element_textarea.style.width = 500

        element_textarea.style.height = 500

        element_textarea.style.font = 'compi'

        element_textarea.style.font_color = { r = 0, g = 0, b = 0 }

        element_textarea.focus()

        element_flow = element_frame.add( { type = 'flow' } )

        element_flow.style.top_padding = 5

        element_flow.style.horizontal_align = 'left'

        element_flow.style.horizontally_stretchable = true

        local element_button = element_flow.add( { type = 'button', name = name_main_button_submit, style = 'rounded_button', caption = 'SUBMIT' } )

        element_button.style.minimal_width = 150

        element_label = element_flow.add( { type = 'label', name = name_label_counter, caption = max_support_request_length } )

        element_label.style.top_padding = 3

        element_label.style.minimal_width = 190

        element_label.style.font = 'compi'

        element_label.style.font_color = { r = 1, g = 1, b = 1 }

        element_label.style.horizontal_align = 'center'

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

                    player.gui.center[ name_main_frame ].children[ 2 ].focus()

                end

            else

                draw_main_frame( player )

            end

        end

        if event.element.name == name_main_button_submit then

            local element_textarea_content = event.element.parent.parent.children[ 2 ]

            if element_textarea_content.text == '' then

                player.print( 'The emptiness devours us all.', { r = 1, g = 0, b = 0 } )

                element_textarea_content.focus()

                return

            end

            if string.len( element_textarea_content.text ) > max_support_request_length then

                player.print( 'The message is too long. ' .. max_support_request_length .. ' characters maximum.', { r = 1, g = 0, b = 0 } )

                element_textarea_content.focus()

                return

            end

            player.print( 'The message is transmitted to the collective, you will now be assimilated.', { r = 255, g = 165, b = 0 } )

            element_textarea_content.text = element_textarea_content.text:gsub( '\n', ' ' )

            print_override.raw_print( '[SUPPORT]' .. player.name .. '[REQUEST]' .. element_textarea_content.text )

            player.gui.center[ name_main_frame ].visible = false

        end

        if event.element.name == name_main_button_close then

            player.gui.center[ name_main_frame ].visible = false

        end

    end

    local function on_gui_text_changed( event )

        if event.element.name == name_textarea_content then

            local content_length = string.len( event.element.text );

            local element_counter = event.element.parent.children[ 3 ].children[ 2 ]

            if content_length <= max_support_request_length then element_counter.caption = max_support_request_length - content_length else element_counter.caption = 0 end

        end

    end

    local function draw_headline_button( player )

        if player.gui.top[ name_headline_button ] then player.gui.top[ name_headline_button ].destroy() end

        player.gui.top.add( { type = 'sprite-button', name = name_headline_button, sprite = 'entity/compilatron', tooltip = 'Comfylatron' } )

    end

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        draw_headline_button( player )

    end

    local Event = require 'utils.event'

    Event.add( defines.events.on_player_joined_game, on_player_joined_game )

    Event.add( defines.events.on_gui_text_changed, on_gui_text_changed )

    Event.add( defines.events.on_gui_click, on_gui_click )
