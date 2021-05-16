
    local utils_gui = require 'utils.gui'

    local name_belt_button = utils_gui.uid_name()

    local battle_belt = { 'raw-fish', 'repair-pack', 'construction-robot', 'defender-capsule', 'destroyer-capsule', 'distractor-capsule', 'land-mine', 'stone-wall', 'grenade', 'cluster-grenade', 'gun-turret', 'firearm-magazine', 'piercing-rounds-magazine', 'uranium-rounds-magazine', 'rocket', 'explosive-rocket', 'cannon-shell', 'explosive-cannon-shell', 'uranium-cannon-shell', 'explosive-uranium-cannon-shell' }

    local construction_belt = { 'inserter', 'fast-inserter', 'long-handed-inserter', 'transport-belt', 'underground-belt', 'splitter', 'assembling-machine-1', 'assembling-machine-2', 'small-electric-pole', 'medium-electric-pole', 'electric-mining-drill', 'stone-furnace', 'steel-furnace', 'train-stop', 'rail-signal', 'rail-chain-signal', 'rail', 'boiler', 'steam-engine', 'offshore-pump' }

    local function draw_headline_button( player )

        for index, slot in pairs( battle_belt ) do player.set_quick_bar_slot( index, slot ) end

        if player.gui.top[ name_belt_button ] then player.gui.top[ name_belt_button ].destroy() end

        player.gui.top.add( { type = 'sprite-button', name = name_belt_button, sprite = 'item/repair-pack', tooltip = 'BELT' } )

    end

    local function on_player_joined_game( event )

        if not global.game_players_memory[ event.player_index ] then global.game_players_memory[ event.player_index ] = {} end

        if not global.game_players_memory[ event.player_index ].belt then global.game_players_memory[ event.player_index ].belt = 'battle' end

        local player = game.players[ event.player_index ]

        draw_headline_button( player )

    end

    local function on_gui_click( event )

        if not event.element.valid then return end

        local player = game.players[ event.player_index ]

        if event.element.name == name_belt_button then

            if global.game_players_memory[ player.index ].belt == 'battle' then

                global.game_players_memory[ player.index ].belt = 'construction'

                for index, slot in pairs( construction_belt ) do player.set_quick_bar_slot( index, slot ) end

            else

                global.game_players_memory[ player.index ].belt = 'battle'

                for index, slot in pairs( battle_belt ) do player.set_quick_bar_slot( index, slot ) end

            end

        end

    end

    local function on_player_left_game( event )

        if global.game_players_memory[ event.player_index ].belt then global.game_players_memory[ event.player_index ].belt = nil end

    end

    local Event = require 'utils.event'

    Event.on_init( on_init )

    Event.add( defines.events.on_player_joined_game, on_player_joined_game )

    Event.add( defines.events.on_gui_click, on_gui_click )

    Event.add( defines.events.on_player_left_game, on_player_left_game )
