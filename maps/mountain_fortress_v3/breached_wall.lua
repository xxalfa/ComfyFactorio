local Collapse = require 'modules.collapse'
local Terrain = require 'maps.mountain_fortress_v3.terrain'
local Balance = require 'maps.mountain_fortress_v3.balance'
local RPG_Settings = require 'modules.rpg.table'
local Functions = require 'modules.rpg.functions'
local WPT = require 'maps.mountain_fortress_v3.table'
local Alert = require 'utils.alert'
local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'

local raise_event = script.raise_event
local floor = math.floor
local random = math.random
local sqrt = math.sqrt
local concat = table.concat

local keeper = '[color=blue]Mapkeeper:[/color] \n'

local collapse_message =
    Token.register(
    function(data)
        local pos = data.position
        local message = keeper .. 'Warning, Collapse has begun!'
        local collapse_position = {
            position = pos
        }
        Alert.alert_all_players_location(collapse_position, message)
    end
)

local spidertron_unlocked =
    Token.register(
    function()
        local message = 'Attention! Spidertron has been unlocked at the main market!'
        Alert.alert_all_players(30, message, nil, 'achievement/tech-maniac', 0.1)
    end
)

local zone_complete =
    Token.register(
    function(data)
        local bonus = data.bonus
        local player = data.player
        local message = keeper .. 'Survivor! Well done. You have completed zone: ' .. bonus
        Alert.alert_player_warning(player, 10, message)
    end
)

local first_player_to_zone =
    Token.register(
    function(data)
        local player = data.player
        local breached_wall = data.breached_wall
        local message = concat {keeper .. player.name .. ' was the first to reach zone ' .. breached_wall .. '.'}
        Alert.alert_all_players(10, message)
    end
)

local artillery_warning =
    Token.register(
    function()
        local message = keeper .. 'Warning, Artillery have been spotted north!'
        Alert.alert_all_players(10, message)
    end
)

local function distance(player)
    local rpg_t = RPG_Settings.get('rpg_t')
    local rpg_extra = RPG_Settings.get('rpg_extra')
    local bonus = rpg_t[player.index].bonus
    local breached_wall = WPT.get('breached_wall')
    local bonus_xp_on_join = WPT.get('bonus_xp_on_join')
    local enable_arties = WPT.get('enable_arties')

    local distance_to_center = floor(sqrt(player.position.x ^ 2 + player.position.y ^ 2))
    local location = distance_to_center
    if location < Terrain.level_depth * bonus - 10 then
        return
    end

    local max = Terrain.level_depth * bonus
    local breach_max = Terrain.level_depth * breached_wall
    local breach_max_times = location >= breach_max
    local max_times = location >= max
    if max_times then
        if breach_max_times then
            rpg_extra.breached_walls = rpg_extra.breached_walls + 1
            rpg_extra.reward_new_players = bonus_xp_on_join * rpg_extra.breached_walls
            WPT.set().breached_wall = breached_wall + 1
            WPT.set().placed_trains_in_zone.placed = 0
            WPT.set().placed_trains_in_zone.randomized = false
            WPT.set().placed_trains_in_zone.positions = {}
            raise_event(Balance.events.breached_wall, {})

            if WPT.get('breached_wall') == WPT.get('spidertron_unlocked_at_wave') then
                local main_market_items = WPT.get('main_market_items')
                if not main_market_items['spidertron'] then
                    local rng = random(70000, 120000)
                    main_market_items['spidertron'] = {
                        stack = 1,
                        value = 'coin',
                        price = rng,
                        tooltip = 'Chonk Spidertron',
                        upgrade = false,
                        static = true
                    }
                    Task.set_timeout_in_ticks(150, spidertron_unlocked)
                end
            end

            local data = {
                player = player,
                breached_wall = breached_wall
            }
            Task.set_timeout_in_ticks(360, first_player_to_zone, data)
            if breached_wall == 5 then
                if enable_arties == 6 then
                    Task.set_timeout_in_ticks(360, artillery_warning)
                end
            end
        end
        if not Collapse.start_now() then
            Collapse.start_now(true)
            local data = {
                position = Collapse.get_position()
            }
            Task.set_timeout_in_ticks(550, collapse_message, data)
        end
        rpg_t[player.index].bonus = bonus + 1
        local data = {
            player = player,
            bonus = bonus
        }
        Task.set_timeout_in_ticks(1, zone_complete, data)
        Functions.gain_xp(player, bonus_xp_on_join * bonus)
        return
    end
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    local map_name = 'mountain_fortress_v3'

    if string.sub(player.surface.name, 0, #map_name) ~= map_name then
        return
    end

    distance(player)
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
