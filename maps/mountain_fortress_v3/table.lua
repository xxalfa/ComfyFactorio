-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    players = {},
    offline_players = {},
    --[[ hidden_dimension = {
        logistic_research_level = 0,
        reset_counter = 1
    },
    ]]
    breached_wall = 1,
    traps = {}
}
local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

function Public.reset_table()
    -- @start
    -- these 3 are in case of stop/start/reloading the instance.
    this.soft_reset = true
    this.restart = false
    this.shutdown = false
    this.announced_message = false
    -- @end
    this.icw_locomotive = nil
    this.debug = false
    this.game_lost = false
    this.fullness_enabled = true
    this.locomotive_health = 10000
    this.locomotive_max_health = 10000
    this.train_upgrades = 0
    this.offline_players = {}
    this.biter_pets = {}
    this.flamethrower_damage = {}
    this.mined_scrap = 0
    this.biters_killed = 0
    this.locomotive_xp_aura = 40
    this.xp_points = 0
    this.xp_points_upgrade = 0
    --!grief prevention
    this.enable_arties = 5 -- default to callback 6
    --!snip
    this.poison_deployed = false
    this.upgrades = {
        showed_text = false,
        landmine = {
            limit = 25,
            bought = 0,
            built = 0
        },
        flame_turret = {
            limit = 6,
            bought = 0,
            built = 0
        },
        unit_number = {
            landmine = {},
            flame_turret = {}
        }
    }
    if this.hidden_dimension then
        this.hidden_dimension.logistic_research_level = 0
    end
    this.aura_upgrades = 0
    this.health_upgrades = 0
    this.breached_wall = 1
    this.offline_players_enabled = true
    this.left_top = {
        x = 0,
        y = 0
    }
    this.traps = {}
    this.munch_time = true
    this.coin_amount = 1
    this.difficulty_set = false
    this.bonus_xp_on_join = 250
    this.main_market_items = {}
    this.spill_items_to_surface = false
    this.outside_chests = {}
    this.chests_linked_to = {}
    this.chest_limit_outside_upgrades = 1
    this.force_mining_speed = {
        speed = 0
    }
    this.placed_trains_in_zone = {
        placed = 0,
        positions = {},
        limit = 5,
        randomized = false
    }
    this.collapse_grace = true
    this.explosive_bullets = false
    this.locomotive_biter = nil
    this.disconnect_wagon = false
    this.math_difficulty = 9999
    this.spidertron_unlocked_at_wave = 11
    -- this.void_or_tile = 'lab-dark-2'
    this.void_or_tile = 'out-of-map'
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key)
    if key then
        return this[key]
    else
        return this
    end
end

local on_init = function()
    Public.reset_table()
end

Event.on_init(on_init)

return Public
