
    local table_of_chests = { 'wooden-chest', 'iron-chest', 'steel-chest' }

    local table_of_loots = {}

    table_of_loots[ 1 ] = { name = 'coal', count = 42 }

    table_of_loots[ 2 ] = { name = 'raw-fish', count = 10 }

    table_of_loots[ 3 ] = { name = 'car', count = 1 }

    table_of_loots[ 4 ] = { name = 'repair-pack', count = 10 }

    table_of_loots[ 5 ] = { name = 'construction-robot', count = 10 }

    table_of_loots[ 6 ] = { name = 'defender-capsule', count = 10 }

    table_of_loots[ 7 ] = { name = 'destroyer-capsule', count = 10 }

    table_of_loots[ 8 ] = { name = 'distractor-capsule', count = 10 }

    table_of_loots[ 9 ] = { name = 'land-mine', count = 25 }

    table_of_loots[ 10 ] = { name = 'stone-wall', count = 50 }

    table_of_loots[ 11 ] = { name = 'gun-turret', count = 20 }

    table_of_loots[ 12 ] = { name = 'piercing-rounds-magazine', count = 100 }

    table_of_loots[ 13 ] = { name = 'uranium-rounds-magazine', count = 50 }

    table_of_loots[ 14 ] = { name = 'piercing-shotgun-shell', count = 20 }

    table_of_loots[ 15 ] = { name = 'flamethrower-ammo', count = 20 }

    table_of_loots[ 16 ] = { name = 'rocket', count = 100 }

    table_of_loots[ 17 ] = { name = 'explosive-rocket', count = 50 }

    table_of_loots[ 18 ] = { name = 'grenade', count = 50 }

    table_of_loots[ 19 ] = { name = 'cluster-grenade', count = 25 }

    table_of_loots[ 20 ] = { name = 'cannon-shell', count = 50 }

    table_of_loots[ 21 ] = { name = 'explosive-cannon-shell', count = 25 }

    table_of_loots[ 22 ] = { name = 'uranium-cannon-shell', count = 25 }

    table_of_loots[ 23 ] = { name = 'explosive-uranium-cannon-shell', count = 25 }

    table_of_loots[ 24 ] = { name = 'night-vision-equipment', count = 1 }

    table_of_loots[ 25 ] = { name = 'personal-laser-defense-equipment', count = 1 }

    table_of_loots[ 26 ] = { name = 'personal-roboport-mk2-equipment', count = 1 }

    table_of_loots[ 27 ] = { name = 'power-armor', count = 1 }

    table_of_loots[ 28 ] = { name = 'exoskeleton-equipment', count = 1 }

    table_of_loots[ 29 ] = { name = 'battery-mk2-equipment', count = 1 }

    table_of_loots[ 30 ] = { name = 'energy-shield-equipment', count = 1 }

    table_of_loots[ 31 ] = { name = 'solar-panel-equipment', count = 10 }

    table_of_loots[ 32 ] = { name = 'fusion-reactor-equipment', count = 1 }

    table_of_loots[ 33 ] = { name = 'solid-fuel', count = 10 }

    table_of_loots[ 34 ] = { name = 'rocket-fuel', count = 2 }

    table_of_loots[ 35 ] = { name = 'nuclear-fuel', count = 1 }

    local function on_player_joined_game( event )

        if not global.game_players_memory[ event.player_index ] then global.game_players_memory[ event.player_index ] = {} end

        if not global.game_players_memory[ event.player_index ].boxes_looted then global.game_players_memory[ event.player_index ].boxes_looted = 0 end

    end

    local function on_chunk_generated( event )

        if event.surface.name == 'nauvis' then return end

        if not global.loot_box_chance then global.loot_box_chance = 3000 end

        local chunk_position = { x = event.area.left_top.x, y = event.area.left_top.y }

        for x = 0, 31 do for y = 0, 31 do

            local tile_position = { x = chunk_position.x + x, y = chunk_position.y + y }

            if math.random( 1, global.loot_box_chance ) == 1 and event.surface.can_place_entity( { name = 'wooden-chest', force = 'enemy', position = tile_position } ) then

                local chest_name = table_of_chests[ math.random( 1, #table_of_chests ) ]

                event.surface.create_entity( { name = chest_name, force = 'enemy', position = tile_position } )

            end

        end end

    end

    local function on_entity_died( event )

        if not event.cause then return end

        if not event.cause.valid then return end

        if global.game_stage == nil or global.game_stage ~= 'ongoing_game' then return end

        if event.entity.name == 'wooden-chest' or event.entity.name == 'iron-chest' or event.entity.name == 'steel-chest' and event.entity.force.name == 'enemy' then

            if event.cause.name == 'character' then

                global.game_players_memory[ event.cause.player.index ].boxes_looted = global.game_players_memory[ event.cause.player.index ].boxes_looted + 1

            elseif event.cause.name == 'car' or event.cause.name == 'tank' or event.cause.name == 'train' then

                local driver = event.cause.get_driver()

                if driver.player then global.game_players_memory[ driver.player.index ].boxes_looted = global.game_players_memory[ driver.player.index ].boxes_looted + 1 end

            end

            local loot = table_of_loots[ math.random( 1, #table_of_loots ) ]

            event.entity.surface.spill_item_stack( event.entity.position, loot, true )

            event.entity.surface.create_entity( { name = 'flying-text', position = event.entity.position, text = '+' .. loot.count .. ' ' .. string.upper( loot.name:gsub( '-', ' ' ) ), color = { r = 220, g = 220, b = 220 } } )

        end

    end

    local function on_built_entity( event )

        if global.game_stage == nil or global.game_stage ~= 'ongoing_game' then return end

        if event.created_entity.name == 'wooden-chest' or event.created_entity.name == 'iron-chest' or event.created_entity.name == 'steel-chest' then

            event.created_entity.destroy()

            local player = game.players[ event.player_index ]

            player.print( 'It is not allowed to put boxes.' )

        end

    end

    local function on_player_left_game( event )

        if global.game_players_memory[ event.player_index ].boxes_looted then global.game_players_memory[ event.player_index ].boxes_looted = nil end

    end

    local Event = require 'utils.event'

    Event.add( defines.events.on_player_joined_game, on_player_joined_game )

    Event.add( defines.events.on_chunk_generated, on_chunk_generated )

    Event.add( defines.events.on_entity_died, on_entity_died )

    Event.add( defines.events.on_built_entity, on_built_entity )

    Event.add( defines.events.on_player_left_game, on_player_left_game )
