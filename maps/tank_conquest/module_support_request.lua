
    local event = require 'utils.event'

    local gui = require 'utils.gui'

    local print_override = require 'utils.print_override'

    local max_support_request_length = 1000

    local button_name_support_request = gui.uid_name()

    local frame_name_support_request = gui.uid_name()

    local textarea_name_content = gui.uid_name()

    local button_name_submit = gui.uid_name()

    local label_name_counter = gui.uid_name()

    local button_name_close = gui.uid_name()

    local function draw_button_support_request( player )

        if player.gui.top[ button_name_support_request ] then return end

        player.gui.top.add( { type = 'sprite-button', name = button_name_support_request, sprite = 'entity/compilatron', tooltip = 'Comfylatron' } )

    end

    local function draw_frame_support_request( player )

        if player.gui.center[ frame_name_support_request ] then player.gui.center[ frame_name_support_request ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = frame_name_support_request, direction = 'vertical' } )

        local element_flow = element_frame.add( { type = 'flow' } )

        element_flow.style.horizontal_align = 'center'

        element_flow.style.horizontally_stretchable = true

        local element_label = element_flow.add( { type = 'label', caption = 'SUPPORT • FEEDBACK • SUGGESTION • REPORT A BUG' } )

        element_label.style.font = 'compi'

        element_label.style.font_color = { r = 1, g = 1, b = 1 }

        local element_textarea = element_frame.add( { type = 'text-box', name = textarea_name_content } )

        element_textarea.style.padding = 5

        element_textarea.style.width = 500

        element_textarea.style.height = 500

        element_textarea.style.font = 'compi'

        element_textarea.style.font_color = { r = 0, g = 0, b = 0 }

        element_textarea.focus()

        local element_flow = element_frame.add( { type = 'flow', style= 'quest_item_icons_wrapper' } )

        element_flow.style.top_padding = 5

        element_flow.style.horizontal_align = 'left'

        element_flow.style.horizontally_stretchable = true

        local element_button = element_flow.add( { type = 'button', name = button_name_close, style = 'red_back_button', caption = 'CLOSE' } )

        element_button.style.minimal_width = 150

        local element_label = element_flow.add( { type = 'label', name = label_name_counter, caption = max_support_request_length } )

        element_label.style.top_padding = 4

        element_label.style.minimal_width = 170

        element_label.style.font = 'compi'

        element_label.style.font_color = { r = 1, g = 1, b = 1 }

        element_label.style.horizontal_align = 'center'

        local element_button = element_flow.add( { type = 'button', name = button_name_submit, style = 'confirm_button', caption = 'SUBMIT' } )

        element_button.style.minimal_width = 150

    end

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        if event.element.valid and event.element.name == button_name_support_request then

            if player.gui.center[ frame_name_support_request ] then

                if player.gui.center[ frame_name_support_request ].visible == true then

                    player.gui.center[ frame_name_support_request ].visible = false

                else

                    player.gui.center[ frame_name_support_request ].visible = true

                    player.gui.center[ frame_name_support_request ].children[ 2 ].focus()

                end

            else

                draw_frame_support_request( player )

            end

        end

        if event.element.valid and event.element.name == button_name_submit then

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

            element_textarea_content.text = element_textarea_content.text:gsub('\n', ' ')

            print_override.raw_print( '[SUPPORT]' .. player.name .. '[REQUEST]' .. element_textarea_content.text )

            player.gui.center[ frame_name_support_request ].visible = false

        end

        if event.element.valid and event.element.name == button_name_close then

            player.gui.center[ frame_name_support_request ].visible = false

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_gui_text_changed( event )

        local player = game.players[ event.player_index ]

        if event.element.name == textarea_name_content then

            local content_length = string.len( event.element.text );

            local element_counter = event.element.parent.children[ 3 ].children[ 2 ]

            if content_length <= max_support_request_length then element_counter.caption = max_support_request_length - content_length else element_counter.caption = 0 end

        end

    end

    event.add( defines.events.on_gui_text_changed, on_gui_text_changed )

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        draw_button_support_request( player )

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )
