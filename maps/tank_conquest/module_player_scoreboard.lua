
    local event = require 'utils.event'

    local gui = require 'utils.gui'

    local function draw_gui_score_button( player )

        if player.gui.top[ 'draw_gui_score_button' ] then player.gui.top[ 'draw_gui_score_button' ].destroy() end

        player.gui.top.add( { type = 'sprite-button', name = 'draw_gui_score_button', sprite = 'item/heavy-armor', tooltip = 'SCORE' } )

    end

    local function draw_gui_score_frame( player )

        if player.gui.center[ 'draw_gui_score_frame' ] then player.gui.center[ 'draw_gui_score_frame' ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = 'draw_gui_score_frame', direction = 'vertical' } )

        element_frame.style.padding = 0

        element_frame.style.margin = 0

        element_frame.style.vertical_align = 'center'

        element_frame.style.horizontal_align = 'center'

        local element_table = element_frame.add( { type = 'table', column_count = 14, draw_horizontal_lines = true } )

        element_table.style.padding = 0

        element_table.style.margin = 0

        element_table.style.vertical_align = 'center'

        element_table.style.horizontal_align = 'center'

        local element_label = element_table.add( { type = 'label', caption = global.table_of_properties[ 'force_player_one' ].icon } )

        local element_label = element_table.add( { type = 'label', caption = '#' } )

        local element_label = element_table.add( { type = 'label', caption = 'NAME' } )

        local element_label = element_table.add( { type = 'label', caption = 'CLASS' } )

        local element_label = element_table.add( { type = 'label', caption = 'K' } )

        local element_label = element_table.add( { type = 'label', caption = 'D' } )

        local element_label = element_table.add( { type = 'label', caption = 'POINTS' } )

        local element_label = element_table.add( { type = 'label', caption = global.table_of_properties[ 'force_player_two' ].icon } )

        local element_label = element_table.add( { type = 'label', caption = '#' } )

        local element_label = element_table.add( { type = 'label', caption = 'NAME' } )

        local element_label = element_table.add( { type = 'label', caption = 'CLASS' } )

        local element_label = element_table.add( { type = 'label', caption = 'K' } )

        local element_label = element_table.add( { type = 'label', caption = 'D' } )

        local element_label = element_table.add( { type = 'label', caption = 'POINTS' } )

        for index = 1, 14 * 32 do

            local element_label = element_table.add( { type = 'label', caption = '•' } )

        end

        for _, element_item in pairs( element_table.children ) do

            element_item.style.padding = 0

            element_item.style.bottom_padding = 1

            element_item.style.margin = 0

            element_item.style.vertical_align = 'center'

            element_item.style.horizontal_align = 'center'

            element_item.style.font = 'default-tiny-bold'

            element_item.style.font_color = global.table_of_colors.white

        end

    end

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        if event.element.valid and event.element.name == 'draw_gui_score_button' then

            if player.gui.center[ 'draw_gui_score_frame' ] then player.gui.center[ 'draw_gui_score_frame' ].destroy() else draw_gui_score_frame( player ) end

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        -- if player.admin then draw_gui_score_button( player ) end

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )
