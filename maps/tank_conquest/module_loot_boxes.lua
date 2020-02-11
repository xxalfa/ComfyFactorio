
    local event = require 'utils.event'

    local table_of_loots = { { name = 'iron-ore', count = 50 }, { name = 'copper-ore', count = 50 }, { name = 'stone', count = 50 }, { name = 'coal', count = 50 }, { name = 'defender-capsule', count = 10 }, { name = 'land-mine', count = 20 }, { name = 'gun-turret', count = 5 }, { name = 'piercing-rounds-magazine', count = 50 }, { name = 'uranium-rounds-magazine', count = 10 }, { name = 'combat-shotgun', count = 1 }, { name = 'shotgun-shell', count = 20 }, { name = 'piercing-shotgun-shell', count = 20 }, { name = 'flamethrower', count = 1 }, { name = 'flamethrower-ammo', count = 20 }, { name = 'rocket-launcher', count = 1 }, { name = 'rocket', count = 20 }, { name = 'explosive-rocket', count = 10 }, { name = 'atomic-bomb', count = 1 }, { name = 'grenade', count = 20 }, { name = 'cluster-grenade', count = 10 }, { name = 'cannon-shell', count = 20 }, { name = 'explosive-cannon-shell', count = 10 }, { name = 'uranium-cannon-shell', count = 5 }, { name = 'explosive-uranium-cannon-shell', count = 5 }, { name = 'modular-armor', count = 1 }, { name = 'power-armor', count = 1 }, { name = 'power-armor-mk2', count = 1 }, { name = 'exoskeleton-equipment', count = 1 }, { name = 'battery-mk2-equipment', count = 1 }, { name = 'energy-shield-equipment', count = 1 }, { name = 'fusion-reactor-equipment', count = 1 }, { name = 'solid-fuel', count = 20 }, { name = 'rocket-fuel', count = 10 }, { name = 'nuclear-fuel', count = 1 }, { name = 'gate', count = 10 }, { name = 'stone-wall', count = 20 } }

    local function on_chunk_generated( event )

        if event.surface.name ~= 'tank_conquest' then return end

        local chunk_position = { x = event.area.left_top.x, y = event.area.left_top.y }

        for x = 0, 31 do for y = 0, 31 do

            local tile_position = { x = chunk_position.x + x, y = chunk_position.y + y }

            if math.random( 1, 3000 ) == 1 and event.surface.can_place_entity( { name = 'wooden-chest', force = 'enemy', position = tile_position } ) then event.surface.create_entity( { name = 'wooden-chest', force = 'enemy', position = tile_position } ) end

        end end

    end

    event.add( defines.events.on_chunk_generated, on_chunk_generated )

    local function on_entity_died( event )

        if global.table_of_properties.game_stage ~= 'ongoing_game' then return end

        if event.entity.name == 'wooden-chest' and event.entity.force.name == 'enemy' then

            local loot = table_of_loots[ math.random( 1, #table_of_loots ) ]

            event.entity.surface.spill_item_stack( event.entity.position, loot, true )

            event.entity.surface.create_entity( { name = 'flying-text', position = event.entity.position, text = '+' .. loot.count .. ' ' .. loot.name, color = global.table_of_colors.white } )

        end

    end

    event.add( defines.events.on_entity_died, on_entity_died )