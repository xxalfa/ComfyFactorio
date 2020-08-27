local Global = require 'utils.global'
local Session = require 'utils.datastore.session_data'
local Game = require 'utils.game'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Utils = require 'utils.core'

local jailed_data_set = 'jailed'
local jailed = {}
local player_data = {}
local votejail = {}
local votefree = {}
local settings = {
    playtime_for_vote = 25920000, -- 5 days
    playtime_for_instant_jail = 103680000, -- 20 days
    votejail_count = 5
}
local set_data = Server.set_data
local try_get_data = Server.try_get_data
local concat = table.concat

local valid_commands = {
    ['free'] = true,
    ['jail'] = true
}

Global.register(
    {
        jailed = jailed,
        votejail = votejail,
        votefree = votefree,
        settings = settings,
        player_data = player_data
    },
    function(t)
        jailed = t.jailed
        votejail = t.votejail
        votefree = t.votefree
        settings = t.settings
        player_data = t.player_data
    end
)

local Public = {}

local validate_playtime = function(player)
    local tracker = Session.get_session_table()

    local playtime = player.online_time

    if tracker[player.name] then
        playtime = player.online_time + tracker[player.name]
    end

    return playtime
end

local validate_trusted = function(player)
    local trusted = Session.get_trusted_table()

    local is_trusted = false

    if trusted[player.name] then
        is_trusted = true
    end

    return is_trusted
end

local get_player_data = function(player, remove)
    if remove and player_data[player.index] then
        player_data[player.index] = nil
        return
    end
    if not player_data[player.index] then
        player_data[player.index] = {}
    end
    return player_data[player.index]
end

local get_gulag_permission_group = function()
    if not game.permissions.get_group('gulag') then
        local gulag = game.permissions.create_group('gulag')
        gulag.set_allows_action(defines.input_action.cancel_craft, false)
        gulag.set_allows_action(defines.input_action.edit_permission_group, false)
        gulag.set_allows_action(defines.input_action.import_permissions_string, false)
        gulag.set_allows_action(defines.input_action.delete_permission_group, false)
        gulag.set_allows_action(defines.input_action.add_permission_group, false)
        gulag.set_allows_action(defines.input_action.admin_action, false)
        gulag.set_allows_action(defines.input_action.drop_item, false)
        gulag.set_allows_action(defines.input_action.place_equipment, false)
        gulag.set_allows_action(defines.input_action.take_equipment, false)
    end
    local gulag = game.permissions.get_group('gulag')
    return gulag
end

local create_gulag_surface = function()
    local surface = game.surfaces['gulag']
    if not surface then
        local walls = {}
        local tiles = {}
        surface =
            game.create_surface(
            'gulag',
            {
                autoplace_controls = {
                    ['coal'] = {frequency = 23, size = 3, richness = 3},
                    ['stone'] = {frequency = 20, size = 3, richness = 3},
                    ['copper-ore'] = {frequency = 25, size = 3, richness = 3},
                    ['iron-ore'] = {frequency = 35, size = 3, richness = 3},
                    ['uranium-ore'] = {frequency = 20, size = 3, richness = 3},
                    ['crude-oil'] = {frequency = 80, size = 3, richness = 1},
                    ['trees'] = {frequency = 0.75, size = 2, richness = 0.1},
                    ['enemy-base'] = {frequency = 15, size = 0, richness = 1}
                },
                cliff_settings = {cliff_elevation_0 = 1024, cliff_elevation_interval = 10, name = 'cliff'},
                height = 64,
                width = 256,
                peaceful_mode = false,
                seed = 1337,
                starting_area = 'very-low',
                starting_points = {{x = 0, y = 0}},
                terrain_segmentation = 'normal',
                water = 'normal'
            }
        )
        surface.always_day = true
        surface.request_to_generate_chunks({0, 0}, 9)
        surface.force_generate_chunk_requests()
        local area = {left_top = {x = -128, y = -32}, right_bottom = {x = 128, y = 32}}
        for x = area.left_top.x, area.right_bottom.x, 1 do
            for y = area.left_top.y, area.right_bottom.y, 1 do
                tiles[#tiles + 1] = {name = 'black-refined-concrete', position = {x = x, y = y}}
                if x == area.left_top.x or x == area.right_bottom.x or y == area.left_top.y or y == area.right_bottom.y then
                    walls[#walls + 1] = {name = 'stone-wall', force = 'neutral', position = {x = x, y = y}}
                end
            end
        end
        surface.set_tiles(tiles)
        for _, entity in pairs(walls) do
            local e = surface.create_entity(entity)
            e.destructible = false
            e.minable = false
        end

        rendering.draw_text {
            text = 'BAAAAAD HOOOOOMAAAAAN!!',
            surface = surface,
            target = {0, -50},
            color = {r = 0.98, g = 0.66, b = 0.22},
            scale = 10,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    end
    surface = game.surfaces['gulag']
    return surface
end

local teleport_player_to_gulag = function(player, action)
    local p_data = get_player_data(player)

    if action == 'jail' then
        local surface = game.surfaces['gulag']
        p_data.fallback_surface_index = player.surface.index
        player.teleport(surface.find_non_colliding_position('character', {0, 0}, 2, 1), 'gulag')
    elseif action == 'free' then
        if p_data.fallback_surface_index then
            local surface = game.surfaces[p_data.fallback_surface_index]
            player.teleport(
                surface.find_non_colliding_position(
                    'character',
                    game.forces.player.get_spawn_position(surface),
                    3,
                    0,
                    5
                ),
                surface
            )
            get_player_data(player, true)
        end
    end
end

local validate_args = function(player, griefer)
    if not game.players[griefer] then
        Utils.print_to(player, 'Invalid name.')
        return false
    end

    if votejail[player.name] and not player.admin then
        Utils.print_to(player, 'You are currently being investigated since you have griefed.')
        return false
    end

    if votefree[player.name] and not player.admin then
        Utils.print_to(player, 'You are currently being investigated since you have griefed.')
        return false
    end

    if jailed[player.name] and not player.admin then
        Utils.print_to(player, 'You are jailed, you can´t run this command.')
        return false
    end

    if player.name == griefer and not player.admin then
        Utils.print_to(player, 'You can´t select yourself.')
        return false
    end

    if game.players[griefer].admin and not player.admin then
        Utils.print_to(player, 'You can´t select an admin.')
        return false
    end

    return true
end

local vote_to_jail = function(player, griefer)
    if not votejail[griefer] then
        votejail[griefer] = {index = 0, actor = player.name}
        local message = player.name .. ' has started a vote to jail player ' .. griefer
        Utils.print_to(nil, message)
    end
    if not votejail[griefer][player.name] then
        votejail[griefer][player.name] = true
        votejail[griefer].index = votejail[griefer].index + 1
        Utils.print_to(player, 'You have voted to jail player ' .. griefer .. '.')
        if
            votejail[griefer].index >= settings.votejail_count or
                (votejail[griefer].index == #game.connected_players - 1 and
                    #game.connected_players > votejail[griefer].index)
         then
            Public.try_ul_data(griefer, true, votejail[griefer].actor)
        end
    else
        Utils.print_to(player, 'You have already voted to kick ' .. griefer .. '.')
    end
end

local vote_to_free = function(player, griefer)
    if votefree[griefer] and not votefree[griefer] then
        votefree[griefer] = {index = 0, actor = player.name}
        local message = player.name .. ' has started a vote to free player ' .. griefer
        Utils.print_to(nil, message)
    end
    if not votefree[griefer][player.name] then
        votefree[griefer][player.name] = true
        votefree[griefer].index = votefree[griefer].index + 1

        Utils.print_to(player, 'You have voted to free player ' .. griefer .. '.')
        if
            votefree[griefer].index >= settings.votejail_count or
                (votefree[griefer].index == #game.connected_players - 1 and
                    #game.connected_players > votefree[griefer].index)
         then
            Public.try_ul_data(griefer, false, votefree[griefer].actor)
            votejail[griefer] = nil
            votefree[griefer] = nil
        end
    else
        Utils.print_to(player, 'You have already voted to free ' .. griefer .. '.')
    end
    return
end

local jail = function(player, griefer)
    player = player or 'script'
    if jailed[griefer] then
        return false
    end

    if not game.players[griefer] then
        return
    end

    local g = game.players[griefer]
    teleport_player_to_gulag(g, 'jail')

    local permission_group = game.permissions.get_group('prisoner')
    if not permission_group then
        permission_group = game.permissions.create_group('prisoner')
        for action_name, _ in pairs(defines.input_action) do
            permission_group.set_allows_action(defines.input_action[action_name], false)
        end
        permission_group.set_allows_action(defines.input_action.write_to_console, true)
        permission_group.set_allows_action(defines.input_action.gui_click, true)
        permission_group.set_allows_action(defines.input_action.gui_selection_state_changed, true)
    end
    if g.surface.name == 'gulag' then
        local gulag = get_gulag_permission_group()
        gulag.add_player(griefer)
    else
        permission_group.add_player(griefer)
    end
    local message = griefer .. ' has been jailed by ' .. player .. '.'

    if
        game.players[griefer].character and game.players[griefer].character.valid and
            game.players[griefer].character.driving
     then
        game.players[griefer].character.driving = false
    end

    jailed[griefer] = {jailed = true, actor = player}
    set_data(jailed_data_set, griefer, {jailed = true, actor = player})

    Utils.print_to(nil, message)
    Utils.action_warning_embed('{Jailed}', message)
    Utils.print_admins('Jailed ' .. griefer, player)

    game.players[griefer].clear_console()
    Utils.print_to(griefer, message)
    return true
end

local free = function(player, griefer)
    player = player or 'script'
    if not jailed[griefer] then
        return false
    end

    if not game.players[griefer] then
        return
    end

    local g = game.players[griefer]
    teleport_player_to_gulag(g, 'free')

    local permission_group = game.permissions.get_group('Default')
    if g.surface.name == 'gulag' then
        local gulag = get_gulag_permission_group()
        gulag.add_player(griefer)
    else
        permission_group.add_player(griefer)
    end
    local message = griefer .. ' was set free from jail by ' .. player .. '.'

    jailed[griefer] = nil

    set_data(jailed_data_set, griefer, nil)

    if votejail[griefer] then
        votejail[griefer] = nil
    end
    if votefree[griefer] then
        votefree[griefer] = nil
    end

    Utils.print_to(nil, message)
    Utils.action_warning_embed('{Jailed}', message)
    Utils.print_admins('Free´d ' .. griefer .. ' from jail.', player)
    return true
end

local is_jailed =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        if value then
            if value.jailed then
                jail(value.actor, key)
            end
        end
    end
)

local update_jailed =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value or false
        local player = data.player or 'script'
        if value then
            jail(player, key)
        else
            free(player, key)
        end
    end
)

--- Tries to get data from the webpanel and updates the local table with values.
-- @param data_set player token
function Public.try_dl_data(key)
    key = tostring(key)

    local secs = Server.get_current_time()

    if not secs then
        return
    else
        try_get_data(jailed_data_set, key, is_jailed)
    end
end

--- Tries to get data from the webpanel and updates the local table with values.
-- @param data_set player token
function Public.try_ul_data(key, value, player)
    if type(key) == 'table' then
        key = key.name
    end

    key = tostring(key)

    local data = {
        key = key,
        value = value,
        player = player
    }

    Task.set_timeout_in_ticks(1, update_jailed, data)
end

--- Checks if a player exists within the table
-- @param player_name <string>
-- @return <boolean>
function Public.exists(player_name)
    return jailed[player_name] ~= nil
end

--- Prints a list of all players in the player_jailed table.
function Public.print_jailed()
    local result = {}

    for k, _ in pairs(jailed) do
        result[#result + 1] = k
    end

    result = concat(result, ', ')
    Game.player_print(result)
end

--- Returns the table of jailed
-- @return <table>
function Public.get_jailed_table()
    return jailed
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.try_dl_data(player.name)
    end
)

Event.add(
    defines.events.on_console_command,
    function(event)
        local cmd = event.command

        if not valid_commands[cmd] then
            return
        end

        local griefer = event.parameters
        if not griefer then
            return
        end

        if event.player_index then
            local player = game.players[event.player_index]
            local playtime = validate_playtime(player)
            local trusted = validate_trusted(player)

            local success = validate_args(player, griefer)

            if not success then
                return
            end

            if game.players[griefer] then
                griefer = game.players[griefer].name
            end

            if not trusted and not player.admin or playtime <= settings.playtime_for_vote and not player.admin then
                return Utils.print_to(player, 'You are not trusted enough to run this command.')
            end

            if
                trusted and playtime >= settings.playtime_for_vote and playtime < settings.playtime_for_instant_jail and
                    not player.admin
             then
                if cmd == 'jail' then
                    vote_to_jail(player, griefer)
                    return
                elseif cmd == 'free' then
                    vote_to_free(player, griefer)
                    return
                end
            end

            if player.admin or playtime >= settings.playtime_for_instant_jail then
                if cmd == 'jail' then
                    Public.try_ul_data(griefer, true, player.name)
                    return
                elseif cmd == 'free' then
                    Public.try_ul_data(griefer, false, player.name)
                    return
                end
            end
        end
    end
)

Event.on_init(create_gulag_surface)

Server.on_data_set_changed(
    jailed_data_set,
    function(data)
        if data and data.value then
            if data.value.jailed and data.value.actor then
                jail(data.value.actor, data.key)
            end
        else
            free('script', data.key)
        end
    end
)

commands.add_command(
    'jail',
    'Sends the player to gulag!',
    function()
        return
    end
)

commands.add_command(
    'free',
    'Brings back the player from gulag.',
    function()
        return
    end
)

function Public.required_playtime_for_instant_jail(value)
    if value then
        settings.playtime_for_instant_jail = value
    end
    return settings.playtime_for_instant_jail
end

function Public.required_playtime_for_vote(value)
    if value then
        settings.playtime_for_vote = value
    end
    return settings.playtime_for_vote
end

return Public
