
    local event = require 'utils.event'

    local function on_tick( event )

        if game.tick % 30 == 0 and global.table_of_damages ~= nil then

            for _, item in pairs( global.table_of_damages ) do item.surface.create_entity( { name = 'flying-text', position = item.position, text = math.ceil( item.damage ), color = { r = 1, g = 0, b = 1 } } ) end

            global.table_of_damages = nil

        end

    end

    event.add( defines.events.on_tick, on_tick )

    local function on_entity_damaged( event )

        if event.entity.name == 'wooden-chest' then return end

        if not event.entity.unit_number then return end

        if event.final_damage_amount < 1 then return end

        if global.table_of_damages == nil then global.table_of_damages = {} end

        if global.table_of_damages[ event.entity.unit_number ] == nil then global.table_of_damages[ event.entity.unit_number ] = { surface = event.entity.surface, position = event.entity.position, damage = 0 } end

        global.table_of_damages[ event.entity.unit_number ].damage = global.table_of_damages[ event.entity.unit_number ].damage + event.final_damage_amount

    end

    event.add( defines.events.on_entity_damaged, on_entity_damaged )
