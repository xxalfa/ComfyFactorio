
    local utils_gui = require 'utils.gui'

    local name_score_button = utils_gui.uid_name()

    local name_score_frame = utils_gui.uid_name()

    local function draw_main_frame( player )

        if player.gui.center[ name_score_frame ] then player.gui.center[ name_score_frame ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = name_score_frame, direction = 'vertical' } )

        element_frame.style.padding = 0

        element_frame.style.margin = 0

        element_frame.style.vertical_align = 'center'

        element_frame.style.horizontal_align = 'center'

        local element_table = element_frame.add( { type = 'table', column_count = 14, draw_horizontal_lines = true } )

        element_table.style.padding = 0

        element_table.style.margin = 0

        element_table.style.vertical_align = 'center'

        element_table.style.horizontal_align = 'center'

        element_table.add( { type = 'label', caption = global.table_of_properties[ 'force_player_one' ].icon } )

        element_table.add( { type = 'label', caption = '#' } )

        element_table.add( { type = 'label', caption = 'NAME' } )

        element_table.add( { type = 'label', caption = 'CLASS' } )

        element_table.add( { type = 'label', caption = 'K' } )

        element_table.add( { type = 'label', caption = 'D' } )

        element_table.add( { type = 'label', caption = 'POINTS' } )

        element_table.add( { type = 'label', caption = global.table_of_properties[ 'force_player_two' ].icon } )

        element_table.add( { type = 'label', caption = '#' } )

        element_table.add( { type = 'label', caption = 'NAME' } )

        element_table.add( { type = 'label', caption = 'CLASS' } )

        element_table.add( { type = 'label', caption = 'K' } )

        element_table.add( { type = 'label', caption = 'D' } )

        element_table.add( { type = 'label', caption = 'POINTS' } )

        for index = 1, 14 * 32 do

            element_table.add( { type = 'label', caption = '•' } )

        end

        for _, element_item in pairs( element_table.children ) do

            element_item.style.padding = 0

            element_item.style.bottom_padding = 1

            element_item.style.margin = 0

            element_item.style.vertical_align = 'center'

            element_item.style.horizontal_align = 'center'

            element_item.style.font = 'default-tiny-bold'

            element_item.style.font_color = { r = 1, g = 1, b = 1 }

        end

    end

    local function on_gui_click( event )

        if not event.element.valid then return end

        local player = game.players[ event.player_index ]

        if event.element.name == name_score_button then

            if player.gui.center[ name_score_frame ] then player.gui.center[ name_score_frame ].destroy() else draw_main_frame( player ) end

        end

    end

    local function draw_headline_button( player )

        if player.gui.top[ name_score_button ] then player.gui.top[ name_score_button ].destroy() end

        player.gui.top.add( { type = 'sprite-button', name = name_score_button, sprite = 'item/heavy-armor', tooltip = 'SCORE' } )

    end

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        if player.admin then draw_headline_button( player ) end

    end

    local Event = require 'utils.event'

    Event.add( defines.events.on_player_joined_game, on_player_joined_game )

    Event.add( defines.events.on_gui_click, on_gui_click )
