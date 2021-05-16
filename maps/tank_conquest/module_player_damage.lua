
    local damages_to_draw = {}

    local function on_player_joined_game( event )

        if not global.game_players_memory[ event.player_index ] then global.game_players_memory[ event.player_index ] = {} end

        if not global.game_players_memory[ event.player_index ].damage_caused then global.game_players_memory[ event.player_index ].damage_caused = 0 end

    end

    local function on_entity_damaged( event )

        if not event.cause then return end

        if not event.cause.valid then return end

        if not event.entity.unit_number then return end

        if event.final_damage_amount < 1 then return end

        if event.entity.name == 'wooden-chest' or event.entity.name == 'iron-chest' or event.entity.name == 'steel-chest' then return end

        if event.cause.name == 'character' then

            global.game_players_memory[ event.cause.player.index ].damage_caused = global.game_players_memory[ event.cause.player.index ].damage_caused + event.final_damage_amount

        elseif event.cause.name == 'car' or event.cause.name == 'tank' or event.cause.name == 'train' then

            local driver = event.cause.get_driver()

            if driver.player then global.game_players_memory[ driver.player.index ].damage_caused = global.game_players_memory[ driver.player.index ].damage_caused + event.final_damage_amount end

        end

        if not damages_to_draw then damages_to_draw = {} end

        if not damages_to_draw[ event.entity.unit_number ] then damages_to_draw[ event.entity.unit_number ] = { surface = event.entity.surface, position = event.entity.position, damage_caused = 0 } end

        damages_to_draw[ event.entity.unit_number ].damage_caused = damages_to_draw[ event.entity.unit_number ].damage_caused + event.final_damage_amount

    end

    local function on_tick()

        if game.tick % 30 == 0 and damages_to_draw ~= nil then

            for _, item in pairs( damages_to_draw ) do item.surface.create_entity( { name = 'flying-text', position = item.position, text = math.ceil( item.damage_caused ), color = { r = 1, g = 0, b = 1 } } ) end

            damages_to_draw = nil

        end

    end

    local function on_player_left_game( event )

        if global.game_players_memory[ event.player_index ].damage_caused then global.game_players_memory[ event.player_index ].damage_caused = nil end

    end

    local Event = require 'utils.event'

    Event.add( defines.events.on_player_joined_game, on_player_joined_game )

    Event.add( defines.events.on_entity_damaged, on_entity_damaged )

    Event.add( defines.events.on_tick, on_tick )

    Event.add( defines.events.on_player_left_game, on_player_left_game )
