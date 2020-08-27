require 'modules.rocks_broken_paint_tiles'

local Event = require 'utils.event'
local Server = require 'utils.server'
local Map_score = require 'comfy_panel.map_score'
local BiterRolls = require 'modules.wave_defense.biter_rolls'
local Loot = require 'maps.mountain_fortress_v3.loot'
local Pets = require 'maps.mountain_fortress_v3.biter_pets'
local RPG_Settings = require 'modules.rpg.table'
local Functions = require 'modules.rpg.functions'
local Mining = require 'maps.mountain_fortress_v3.mining'
local Terrain = require 'maps.mountain_fortress_v3.terrain'
local BiterHealthBooster = require 'modules.biter_health_booster'
local Difficulty = require 'modules.difficulty_vote'
local Traps = require 'maps.mountain_fortress_v3.traps'
local Locomotive = require 'maps.mountain_fortress_v3.locomotive'
local ExplosiveBullets = require 'maps.mountain_fortress_v3.explosive_gun_bullets'
local Alert = require 'utils.alert'
local Task = require 'utils.task'
local Token = require 'utils.token'
--local HD = require 'modules.hidden_dimension.main'

-- tables
local WPT = require 'maps.mountain_fortress_v3.table'
local WD = require 'modules.wave_defense.table'

-- module
local Public = {}
local random = math.random
local floor = math.floor
local abs = math.abs
local sqrt = math.sqrt
local round = math.round

--local raise_event = script.raise_event

local mapkeeper = '[color=blue]Mapkeeper:[/color]\n'
local comfylatron = '[color=blue]Comfylatron:[/color]\n'

local treasure_chest_messages = {
    "You notice an old crate within the rubble. It's filled with treasure!",
    "You find a chest underneath the broken rocks. It's filled with goodies!",
    'We has found the precious!'
}

local rare_treasure_chest_messages = {
    'Your magic improves. You have found a chest that is filled with rare treasures!',
    "Oh how wonderful. You found a chest underneath the broken rocks. It's filled with rare goodies!",
    "You're a wizard! We have found the rare precious!"
}

local disabled_threats = {
    ['entity-ghost'] = true,
    ['raw-fish'] = true
}

local defeated_messages = {
    "Oh no, the biters nom'ed the train away!",
    "I'm not 100% sure, but - apparently the train was chewed away.",
    'You had one objective - defend the train *-*',
    "Looks like we're resetting cause you did not defend the train ._."
}

local protect_types = {
    ['cargo-wagon'] = true,
    ['artillery-wagon'] = true,
    ['fluid-wagon'] = true,
    ['locomotive'] = true,
    ['reactor'] = true,
    ['car'] = true
}

local reset_game =
    Token.register(
    function(data)
        local this = data.this
        local Reset_map = data.reset_map
        if this.soft_reset then
            this.game_reset_tick = nil
            Reset_map()
            return
        end
        if this.restart then
            local message = 'Soft-reset is disabled! Server will restart from scenario to load new changes.'
            Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
            Server.start_scenario('Mountain_Fortress_v3')
            this.announced_message = true
            return
        end
        if this.shutdown then
            local message = 'Soft-reset is disabled! Server will shutdown. Most likely because of updates.'
            Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
            Server.stop_scenario()
            return
        end
    end
)

local function set_objective_health(final_damage_amount)
    local this = WPT.get()
    if final_damage_amount == 0 then
        return
    end

    if not this.locomotive then
        return
    end
    if not this.locomotive.valid then
        return
    end

    if this.locomotive_health <= 5000 then
        if not this.poison_deployed then
            for i = 1, 2, 1 do
                Locomotive.enable_poison_defense()
            end
            local p = {
                position = this.locomotive.position
            }
            local msg = comfylatron .. 'Train is taking heavy damage.\nDeploying defense mechanisms.'
            Alert.alert_all_players_location(p, msg)
            this.poison_deployed = true
        end
    elseif this.locomotive_health >= this.locomotive_max_health then
        this.poison_deployed = false
    end

    if this.locomotive_health <= 0 then
        this.locomotive.health = this.locomotive.health + final_damage_amount
        return
    end

    this.locomotive_health = floor(this.locomotive_health - final_damage_amount)
    if this.locomotive_health > this.locomotive_max_health then
        this.locomotive_health = this.locomotive_max_health
    end

    if this.locomotive_health <= 0 then
        Public.loco_died()
    end

    local m = this.locomotive_health / this.locomotive_max_health
    this.locomotive.health = 1000 * m

    rendering.set_text(this.health_text, 'HP: ' .. this.locomotive_health .. ' / ' .. this.locomotive_max_health)
end

local function protect_entities(event)
    local this = WPT.get()
    local entity = event.entity

    if entity.force.index ~= 1 then
        return
    end --Player Force

    local function is_protected(e)
        local map_name = 'mountain_fortress_v3'

        if string.sub(e.surface.name, 0, #map_name) ~= map_name then
            return true
        end
        if protect_types[e.type] then
            return true
        end
        return false
    end

    if is_protected(entity) then
        if event.cause and event.cause.valid then
            if event.cause.force.index == 2 and entity.unit_number == this.locomotive.unit_number then
                set_objective_health(event.final_damage_amount)
            elseif event.cause.force.index == 2 then
                return
            else
                event.entity.health = event.entity.health + event.final_damage_amount
            end
        end
        event.entity.health = event.entity.health + event.final_damage_amount
    end
end

local function hidden_biter(entity)
    local surface = entity.surface
    local h = floor(abs(entity.position.y))
    local m = 1 / Terrain.level_depth
    local count = floor(random(0, h + Terrain.level_depth) * m) + 1
    local position = surface.find_non_colliding_position('small-biter', entity.position, 16, 0.5)
    if not position then
        position = entity.position
    end

    BiterRolls.wave_defense_set_unit_raffle(h * 0.20)

    for _ = 1, count, 1 do
        local unit
        if random(1, 3) == 1 then
            unit = surface.create_entity({name = BiterRolls.wave_defense_roll_spitter_name(), position = position})
        else
            unit = surface.create_entity({name = BiterRolls.wave_defense_roll_biter_name(), position = position})
        end

        if random(1, 64) == 1 then
            BiterHealthBooster.add_boss_unit(unit, m * h * 5 + 1, 0.38)
        end
    end
end

local function hidden_worm(entity)
    BiterRolls.wave_defense_set_worm_raffle(sqrt(entity.position.x ^ 2 + entity.position.y ^ 2) * 0.20)
    entity.surface.create_entity({name = BiterRolls.wave_defense_roll_worm_name(), position = entity.position})
end

local function hidden_biter_pet(event)
    if random(1, 2048) ~= 1 then
        return
    end
    BiterRolls.wave_defense_set_unit_raffle(sqrt(event.entity.position.x ^ 2 + event.entity.position.y ^ 2) * 0.25)
    local unit
    if random(1, 3) == 1 then
        unit =
            event.entity.surface.create_entity(
            {name = BiterRolls.wave_defense_roll_spitter_name(), position = event.entity.position}
        )
    else
        unit =
            event.entity.surface.create_entity(
            {name = BiterRolls.wave_defense_roll_biter_name(), position = event.entity.position}
        )
    end
    Pets.biter_pets_tame_unit(game.players[event.player_index], unit, true)
end

local function hidden_treasure(event)
    local player = game.players[event.player_index]
    local rpg = RPG_Settings.get('rpg_t')
    local magic = rpg[player.index].magicka
    local name = Difficulty.get('name')
    if name == 'Easy' then
        if random(1, 220) ~= 1 then
            return
        end
    elseif name == 'Normal' then
        if random(1, 320) ~= 1 then
            return
        end
    elseif name == 'Hard' then
        if random(1, 420) ~= 1 then
            return
        end
    elseif name == 'Insane' then
        if random(1, 520) ~= 1 then
            return
        end
    end

    if magic > 50 then
        local msg = rare_treasure_chest_messages[random(1, #rare_treasure_chest_messages)]
        Alert.alert_player(player, 5, msg)
        Loot.add_rare(event.entity.surface, event.entity.position, 'wooden-chest', magic)
        return
    end
    local msg = treasure_chest_messages[random(1, #treasure_chest_messages)]
    Alert.alert_player(player, 5, msg)
    Loot.add(event.entity.surface, event.entity.position, 'wooden-chest')
end

local function biters_chew_rocks_faster(event)
    if event.entity.force.index ~= 3 then
        return
    end --Neutral Force
    if not event.cause then
        return
    end
    if not event.cause.valid then
        return
    end
    if event.cause.force.index ~= 2 then
        return
    end --Enemy Force

    event.entity.health = event.entity.health - event.final_damage_amount * 7
end

local projectiles = {'grenade', 'explosive-rocket', 'grenade', 'explosive-rocket', 'explosive-cannon-projectile'}
local function angry_tree(entity, cause)
    if entity.type ~= 'tree' then
        return
    end

    if abs(entity.position.y) < Terrain.level_depth then
        return
    end
    if random(1, 4) == 1 then
        hidden_biter(entity)
    end
    if random(1, 8) == 1 then
        hidden_worm(entity)
    end
    if random(1, 16) ~= 1 then
        return
    end
    local position = false
    if cause then
        if cause.valid then
            position = cause.position
        end
    end
    if not position then
        position = {entity.position.x + (-20 + random(0, 40)), entity.position.y + (-20 + random(0, 40))}
    end

    entity.surface.create_entity(
        {
            name = projectiles[random(1, 5)],
            position = entity.position,
            force = 'neutral',
            source = entity.position,
            target = position,
            max_range = 16,
            speed = 0.01
        }
    )
end

local function give_coin(player)
    local coin_amount = WPT.get('coin_amount')
    if coin_amount >= 1 then
        player.insert({name = 'coin', count = coin_amount})
    end
end

local function on_player_mined_entity(event)
    local this = WPT.get()
    local entity = event.entity
    local player = game.players[event.player_index]
    if not player.valid then
        return
    end
    if not entity.valid then
        return
    end
    local rpg = RPG_Settings.get('rpg_t')
    local rpg_char = rpg[player.index]

    local map_name = 'mountain_fortress_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local upg = this.upgrades

    local built = {
        ['land-mine'] = upg.landmine.built,
        ['flamethrower-turret'] = upg.flame_turret.built
    }

    local validator = {
        ['land-mine'] = 'landmine',
        ['flamethrower-turret'] = 'flame_turret'
    }

    local name = validator[entity.name]

    if built[entity.name] and entity.force.index == 1 then
        this.upgrades[name].built = this.upgrades[name].built - 1
        if this.upgrades[name].built <= 0 then
            this.upgrades[name].built = 0
        end
    end

    if disabled_threats[entity.name] then
        return
    end

    if entity.type == 'simple-entity' or entity.type == 'tree' then
        this.mined_scrap = this.mined_scrap + 1
        Mining.on_player_mined_entity(event)
        if entity.type == 'tree' then
            if random(1, 2) == 1 then
                give_coin(player)
            end
        else
            give_coin(player)
        end
        if rpg_char.stone_path then
            entity.surface.set_tiles({{name = 'stone-path', position = entity.position}}, true)
        end
        if Locomotive.is_around_train(entity) then
            entity.destroy()
            return
        end

        if random(1, 32) == 1 then
            hidden_biter(event.entity)
            entity.destroy()
            return
        end
        if random(1, 512) == 1 then
            hidden_worm(event.entity)
            entity.destroy()
            return
        end
        if random(1, 512) == 1 then
            Traps(entity.surface, entity.position)
            return
        end
        hidden_biter_pet(event)
        hidden_treasure(event)
        angry_tree(event.entity, game.players[event.player_index].character)
        entity.destroy()
    end
end

local function on_robot_mined_entity(event)
    local this = WPT.get()
    local entity = event.entity

    if not entity.valid then
        return
    end

    local map_name = 'mountain_fortress_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local upg = this.upgrades

    local built = {
        ['land-mine'] = upg.landmine.built,
        ['flamethrower-turret'] = upg.flame_turret.built
    }

    local validator = {
        ['land-mine'] = 'landmine',
        ['flamethrower-turret'] = 'flame_turret'
    }

    local name = validator[entity.name]

    if built[entity.name] and entity.force.index == 1 then
        this.upgrades[name].built = this.upgrades[name].built - 1
        if this.upgrades[name].built <= 0 then
            this.upgrades[name].built = 0
        end
    end
end

local function get_damage(event)
    local entity = event.entity
    local damage = event.original_damage_amount + event.original_damage_amount * random(1, 100)
    if entity.prototype.resistances then
        if entity.prototype.resistances.physical then
            damage = damage - entity.prototype.resistances.physical.decrease
            damage = damage - damage * entity.prototype.resistances.physical.percent
        end
    end
    damage = round(damage, 3)
    if damage < 1 then
        damage = 1
    end
    return damage
end

local function kaboom(entity, target, damage)
    local base_vector = {target.position.x - entity.position.x, target.position.y - entity.position.y}

    local vector = {base_vector[1], base_vector[2]}
    vector[1] = vector[1] * 512
    vector[2] = vector[2] * 256

    local msg = {'TASTY', 'MUNCH', 'SNACK_TIME', 'OVER 9000!'}

    entity.surface.create_entity(
        {
            name = 'flying-text',
            position = {entity.position.x + base_vector[1] * 0.5, entity.position.y + base_vector[2] * 0.5},
            text = msg[random(1, #msg)],
            color = {255, 0, 0}
        }
    )

    if abs(vector[1]) > abs(vector[2]) then
        local d = abs(vector[1])
        if abs(vector[1]) > 0 then
            vector[1] = vector[1] / d
        end
        if abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
    else
        local d = abs(vector[2])
        if abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
        if abs(vector[1]) > 0 and d > 0 then
            vector[1] = vector[1] / d
        end
    end

    vector[1] = vector[1] * 1.6
    vector[2] = vector[2] * 1.6

    local a = 0.30

    for i = 1, 8, 1 do
        for x = i * -1 * a, i * a, 1 do
            for y = i * -1 * a, i * a, 1 do
                local p = {entity.position.x + x + vector[1] * i, entity.position.y + y + vector[2] * i}
                entity.surface.create_trivial_smoke({name = 'fire-smoke', position = p})
                for _, e in pairs(entity.surface.find_entities({{p[1] - a, p[2] - a}, {p[1] + a, p[2] + a}})) do
                    if e.valid then
                        if e.health then
                            if e.destructible and e.minable then
                                if e.force.index ~= entity.force.index then
                                    e.health = e.health - damage * 0.05
                                    if e.health <= 0 then
                                        e.die(e.force.name, entity)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function boss_puncher(event)
    local cause = event.cause
    if not cause then
        return
    end
    if not cause.valid then
        return
    end

    if cause.force.index ~= 2 then
        return
    end

    local entity = event.entity

    if entity.force.index ~= 1 then
        return
    end
    if not entity then
        return
    end
    if not entity.valid then
        return
    end

    if random(1, 10) == 1 then
        kaboom(cause, entity, get_damage(event))
    end
end

local function on_entity_damaged(event)
    local entity = event.entity

    if not entity then
        return
    end

    if not entity.valid then
        return
    end

    local wave_number = WD.get_wave()
    local boss_wave_warning = WD.alert_boss_wave()
    local munch_time = WPT.get('munch_time')

    protect_entities(event)
    biters_chew_rocks_faster(event)

    if munch_time then
        if boss_wave_warning or wave_number >= 1500 then
            if random(0, 512) == 1 then
                boss_puncher(event)
            end
        end
    end
    if WPT.get('explosive_bullets') then
        ExplosiveBullets.explosive_bullets(event)
        return
    end
end

local function on_player_repaired_entity(event)
    local this = WPT.get()
    if not event.entity then
        return
    end
    if not event.entity.valid then
        return
    end
    if not event.entity.health then
        return
    end
    local entity = event.entity
    if entity == this.locomotive then
        local player = game.players[event.player_index]
        local repair_speed = Functions.get_magicka(player)
        if repair_speed <= 0 then
            set_objective_health(-1)
            return
        else
            set_objective_health(-repair_speed)
            return
        end
    end
end

local function on_entity_died(event)
    local this = WPT.get()

    local entity = event.entity
    if not entity.valid then
        return
    end

    local map_name = 'mountain_fortress_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local upg = this.upgrades

    local built = {
        ['land-mine'] = upg.landmine.built,
        ['flamethrower-turret'] = upg.flame_turret.built
    }

    local validator = {
        ['land-mine'] = 'landmine',
        ['flamethrower-turret'] = 'flame_turret'
    }

    local name = validator[entity.name]

    if built[entity.name] and entity.force.index == 1 then
        this.upgrades[name].built = this.upgrades[name].built - 1
        if this.upgrades[name].built <= 0 then
            this.upgrades[name].built = 0
        end
    end

    if event.cause then
        if event.cause.valid then
            if event.cause.force.index == 2 or event.cause.force.index == 3 then
                entity.destroy()
                return
            end
        end
    end

    if disabled_threats[entity.name] then
        return
    end

    if entity.type == 'unit' or entity.type == 'unit-spawner' then
        this.biters_killed = this.biters_killed + 1
        if Locomotive.is_around_train(entity) then
            entity.destroy()
            return
        end
        if random(1, 512) == 1 then
            Traps(entity.surface, entity.position)
            return
        end
    end

    local data = {
        entity = entity,
        surface = entity.surface
    }

    if entity.type == 'tree' then
        for _, e in pairs(
            event.entity.surface.find_entities_filtered(
                {
                    area = {
                        {entity.position.x - 4, entity.position.y - 4},
                        {entity.position.x + 4, entity.position.y + 4}
                    },
                    name = 'fire-flame-on-tree'
                }
            )
        ) do
            if e.valid then
                e.destroy()
                return
            end
        end
        if Locomotive.is_around_train(entity) then
            entity.destroy()
            return
        end
        angry_tree(entity, event.cause)
        return
    end

    if entity.type == 'simple-entity' then
        if Locomotive.is_around_train(entity) then
            entity.destroy()
            return
        end
        if random(1, 32) == 1 then
            hidden_biter(entity)
            Mining.entity_died_randomness(data)
            entity.destroy()
            return
        end
        if random(1, 64) == 1 then
            hidden_worm(entity)
            Mining.entity_died_randomness(data)
            entity.destroy()
            return
        end
        if random(1, 512) == 1 then
            Traps(entity.surface, entity.position)
            Mining.entity_died_randomness(data)
            return
        end
        Mining.entity_died_randomness(data)
        entity.destroy()
        return
    end
end

function Public.set_scores()
    local this = WPT.get()
    local loco = this.locomotive
    if not loco then
        return
    end
    if not loco.valid then
        return
    end
    local score = floor(loco.position.y * -1)
    for _, player in pairs(game.connected_players) do
        if score > Map_score.get_score(player) then
            Map_score.set_score(player, score)
        end
    end
end

function Public.loco_died()
    local this = WPT.get()
    local surface = game.surfaces[this.active_surface_index]
    local wave_defense_table = WD.get_table()
    Public.set_scores()
    if not this.locomotive.valid then
        if this.announced_message then
            return
        end

        local data = {}
        if this.locomotive and this.locomotive.valid then
            data.position = this.locomotive.position
        else
            data.position = {x = 0, y = 0}
        end

        local msg = mapkeeper .. defeated_messages[random(1, #defeated_messages)] .. '\nBetter luck next time.'
        Alert.alert_all_players_location(data, msg, nil, 6000)

        local Reset_map = require 'maps.mountain_fortress_v3.main'.reset_map
        wave_defense_table.game_lost = true
        wave_defense_table.target = nil

        local params = {
            this = this,
            reset_map = Reset_map
        }

        if this.soft_reset then
            this.game_reset_tick = nil
            Task.set_timeout_in_ticks(60, reset_game, params)
            return
        end
        if this.restart then
            if not this.announced_message then
                game.print(
                    'Soft-reset is disabled! Server will restart from scenario to load new changes.',
                    {r = 0.22, g = 0.88, b = 0.22}
                )
                Task.set_timeout_in_ticks(60, reset_game, params)
                this.announced_message = true
                return
            end
        end
        if this.shutdown then
            if not this.announced_message then
                game.print(
                    'Soft-reset is disabled! Server will shutdown. Most likely because of updates.',
                    {r = 0.22, g = 0.88, b = 0.22}
                )
                Task.set_timeout_in_ticks(60, reset_game, params)
                this.announced_message = true
                return
            end
        end

        return
    end
    -- raise_event(
    --     HD.events.reset_game,
    --     {
    --         surface = surface
    --     }
    -- )
    this.locomotive_health = 0
    this.locomotive.color = {0.49, 0, 255, 1}
    rendering.set_text(this.health_text, 'HP: ' .. this.locomotive_health .. ' / ' .. this.locomotive_max_health)
    wave_defense_table.game_lost = true
    wave_defense_table.target = nil
    this.game_lost = true
    local msg
    if this.soft_reset then
        msg =
            mapkeeper ..
            defeated_messages[random(1, #defeated_messages)] ..
                '\nBetter luck next time.\nGame will soft-reset shortly.'
    else
        msg =
            mapkeeper ..
            defeated_messages[random(1, #defeated_messages)] ..
                '\nBetter luck next time.\nGame will not soft-reset. Soft-reset is disabled.'
    end
    local pos = {
        position = this.locomotive.position
    }
    Alert.alert_all_players_location(pos, msg)
    game.forces.enemy.set_friend('player', true)
    game.forces.player.set_friend('enemy', true)

    local fake_shooter =
        surface.create_entity({name = 'character', position = this.locomotive.position, force = 'enemy'})
    surface.create_entity(
        {
            name = 'atomic-rocket',
            position = this.locomotive.position,
            force = 'enemy',
            speed = 1,
            max_range = 1200,
            target = this.locomotive,
            source = fake_shooter
        }
    )

    surface.spill_item_stack(this.locomotive.position, {name = 'coin', count = 512}, false)
    this.game_reset_tick = 5400
    for _, player in pairs(game.connected_players) do
        player.play_sound {path = 'utility/game_lost', volume_modifier = 0.75}
    end
end

local function on_built_entity(event)
    local this = WPT.get()
    local entity = event.created_entity
    if not entity.valid then
        return
    end

    local map_name = 'mountain_fortress_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local upg = this.upgrades
    local surface = entity.surface

    local built = {
        ['land-mine'] = upg.landmine.built,
        ['flamethrower-turret'] = upg.flame_turret.built
    }

    local limit = {
        ['land-mine'] = upg.landmine.limit,
        ['flamethrower-turret'] = upg.flame_turret.limit
    }

    local validator = {
        ['land-mine'] = 'landmine',
        ['flamethrower-turret'] = 'flame_turret'
    }

    local name = validator[entity.name]

    if built[entity.name] and entity.force.index == 1 then
        if built[entity.name] < limit[entity.name] then
            this.upgrades[name].built = built[entity.name] + 1
            this.upgrades.unit_number[name][entity] = entity
            this.upgrades.showed_text = false

            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = this.upgrades[name].built .. ' / ' .. limit[entity.name] .. ' ' .. entity.name,
                    color = {r = 0.82, g = 0.11, b = 0.11}
                }
            )
        else
            if not this.upgrades.showed_text then
                surface.create_entity(
                    {
                        name = 'flying-text',
                        position = entity.position,
                        text = entity.name .. ' limit reached. Purchase more slots at the market!',
                        color = {r = 0.82, g = 0.11, b = 0.11}
                    }
                )

                this.upgrades.showed_text = true
            end
            local player = game.players[event.player_index]
            player.insert({name = entity.name, count = 1})
            entity.destroy()
        end
    end
end

local function on_robot_built_entity(event)
    local this = WPT.get()
    local entity = event.created_entity
    if not entity.valid then
        return
    end

    local map_name = 'mountain_fortress_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local upg = this.upgrades
    local surface = entity.surface

    local built = {
        ['land-mine'] = upg.landmine.built,
        ['flamethrower-turret'] = upg.flame_turret.built
    }

    local limit = {
        ['land-mine'] = upg.landmine.limit,
        ['flamethrower-turret'] = upg.flame_turret.limit
    }

    local validator = {
        ['land-mine'] = 'landmine',
        ['flamethrower-turret'] = 'flame_turret'
    }

    local name = validator[entity.name]

    if built[entity.name] and entity.force.index == 1 then
        if built[entity.name] < limit[entity.name] then
            this.upgrades[name].built = built[entity.name] + 1
            this.upgrades.unit_number[name][entity] = entity
            this.upgrades.showed_text = false

            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = this.upgrades[name].built .. ' / ' .. limit[entity.name] .. ' ' .. entity.name,
                    color = {r = 0.82, g = 0.11, b = 0.11}
                }
            )
        else
            if not this.upgrades.showed_text then
                surface.create_entity(
                    {
                        name = 'flying-text',
                        position = entity.position,
                        text = entity.name .. ' limit reached. Purchase more slots at the market!',
                        color = {r = 0.82, g = 0.11, b = 0.11}
                    }
                )

                this.upgrades.showed_text = true
            end
            local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
            inventory.insert({name = entity.name, count = 1})
            entity.destroy()
        end
    end
end

local on_player_or_robot_built_tile = function(event)
    local surface = game.surfaces[event.surface_index]

    local map_name = 'mountain_fortress_v3'

    if string.sub(surface.name, 0, #map_name) ~= map_name then
        return
    end

    local tiles = event.tiles
    if not tiles then
        return
    end
    for k, v in pairs(tiles) do
        local old_tile = v.old_tile
        if old_tile.name == 'black-refined-concrete' then
            surface.set_tiles({{name = 'black-refined-concrete', position = v.position}}, true)
        end
        if old_tile.name == 'blue-refined-concrete' then
            surface.set_tiles({{name = 'blue-refined-concrete', position = v.position}}, true)
        end
        if old_tile.name == 'cyan-refined-concrete' then
            surface.set_tiles({{name = 'cyan-refined-concrete', position = v.position}}, true)
        end
        if old_tile.name == 'hazard-concrete-right' then
            surface.set_tiles({{name = 'hazard-concrete-right', position = v.position}}, true)
        end
        if old_tile.name == 'lab-dark-2' then
            surface.set_tiles({{name = 'lab-dark-2', position = v.position}}, true)
        end
    end
end

Event.add_event_filter(defines.events.on_entity_damaged, {filter = 'final-damage-amount', comparison = '>', value = 0})
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_player_built_tile, on_player_or_robot_built_tile)
Event.add(defines.events.on_robot_built_tile, on_player_or_robot_built_tile)

return Public
