
    local event = require 'utils.event'

    local gui = require 'utils.gui'

    local function draw_gui_squad_button( player )

        if player.gui.top[ 'draw_gui_squad_button' ] then player.gui.top[ 'draw_gui_squad_button' ].destroy() end

        player.gui.top.add( { type = 'sprite-button', name = 'draw_gui_squad_button', sprite = 'item/personal-roboport-equipment', tooltip = 'SQUAD' } )

    end

    local function draw_gui_squad_frame( player )

        if player.gui.left[ 'draw_gui_squad_frame' ] then player.gui.left[ 'draw_gui_squad_frame' ].destroy() end

        -- if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        local element_frame = player.gui.left.add( { type = 'frame', name = 'draw_gui_squad_frame', direction = 'vertical' } )

        element_frame.style.minimal_width = 50

        element_frame.style.padding = 0

        element_frame.style.margin = 0

        element_frame.style.top_margin = 5

        element_frame.style.left_margin = 5

        local element_table = element_frame.add( { type = 'table', column_count = 4 } )

        element_table.style.padding = 0

        element_table.style.margin = 0

        for index = 1, 8 do

            local element_label = element_table.add( { type = 'label', caption = 'SQUAD ' .. index } )

            local element_label = element_table.add( { type = 'label' } )

            local element_label = element_table.add( { type = 'label' } )

            local element_button = element_table.add( { type = 'sprite-button', name = 'aaa_' .. index, caption = 'JOIN' } )

            element_button.style.width = 50

            element_button.style.height = 25

            local element_label = element_table.add( { type = 'label', caption = '•' } )

            local element_label = element_table.add( { type = 'label', caption = '•' } )

            local element_label = element_table.add( { type = 'label', caption = '•' } )

            local element_label = element_table.add( { type = 'label', caption = '•' } )

        end

        for _, element_item in pairs( element_table.children ) do

            element_item.style.minimal_width = 50

            element_item.style.padding = 0

            element_item.style.margin = 0

            element_item.style.vertical_align = 'center'

            element_item.style.horizontal_align  = 'center'

            element_item.style.font  = 'heading-2'

            element_item.style.font_color = global.table_of_colors.white

        end

    end

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        if event.element.valid and event.element.name == 'draw_gui_squad_button' then

            if player.gui.left[ 'draw_gui_squad_frame' ] then player.gui.left[ 'draw_gui_squad_frame' ].destroy() else draw_gui_squad_frame( player ) end

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        -- if player.admin then draw_gui_squad_button( player ) end

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )
