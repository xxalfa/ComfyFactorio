
    local event = require 'utils.event'

    local battle_belt = { 'raw-fish', 'repair-pack', 'wood', 'defender-capsule', 'stone-wall', 'gun-turret', 'land-mine', 'flamethrower-ammo', 'grenade', 'cluster-grenade', 'firearm-magazine', 'piercing-rounds-magazine', 'uranium-rounds-magazine', 'rocket', 'explosive-rocket', 'atomic-bomb', 'cannon-shell', 'explosive-cannon-shell', 'uranium-cannon-shell', 'explosive-uranium-cannon-shell' }

    local construction_belt = { 'inserter', 'fast-inserter', 'long-handed-inserter', 'transport-belt', 'underground-belt', 'splitter', 'assembling-machine-1', 'assembling-machine-2', 'small-electric-pole', 'medium-electric-pole', 'electric-mining-drill', 'stone-furnace', 'steel-furnace', 'train-stop', 'rail-signal', 'rail-chain-signal', 'rail', 'boiler', 'steam-engine', 'offshore-pump' }

    function draw_gui_belt_button( player )

        if global.table_of_settings[ player.index ].belt == nil then

            global.table_of_settings[ player.index ].belt = 'battle';

            for index, slot in pairs( battle_belt ) do player.set_quick_bar_slot( index, slot ) end

        end

        if player.gui.top[ 'draw_gui_belt_button' ] then player.gui.top[ 'draw_gui_belt_button' ].destroy() end

        player.gui.top.add( { type = 'sprite-button', name = 'draw_gui_belt_button', sprite = 'item/repair-pack', tooltip = 'BELT' } )

    end

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        if event.element.valid and event.element.name == 'draw_gui_belt_button' then

            if global.table_of_settings[ player.index ].belt == 'battle' then

                global.table_of_settings[ player.index ].belt = 'construction'

                for index, slot in pairs( construction_belt ) do player.set_quick_bar_slot( index, slot ) end

            else

                global.table_of_settings[ player.index ].belt = 'battle'

                for index, slot in pairs( battle_belt ) do player.set_quick_bar_slot( index, slot ) end

            end

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        draw_gui_belt_button( player )

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )
