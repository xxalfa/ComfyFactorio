
    local event = require 'utils.event'

    local gui = require 'utils.gui'

    local name_headline_button = gui.uid_name()

    local name_main_frame = gui.uid_name()

    local name_main_button_close = gui.uid_name()

    local scenario_name = 'Tank Battles'

    local scenario_introduction = [[
    This adjusted Factorio scenario is part of the Comfy community, if you are not
    already involved, you are welcome >> getcomfy.eu/discord

    What can you expect in this scenario? In short, action-packed tank battles.

    At the beginning of each round you will be provided with a tank, which will then be
    teleported to a random location, each round has a time frame of approximately
    15 minutes, with the map becoming smaller and smaller towards the center. At the
    end of a round, this will escalate the battle, with the last surviving player
    emerging as the round's winner. The map overview has been switched off to
    make it difficult to find other players.

    You should pay particular attention to two things, on the map there are wooden
    boxes, which provide items for defense, but also for attack. And then every three
    minutes a nuclear warhead is fired at your position, which is to prevent your tank
    from getting unnecessarily cold.

    To start a round, at least two players must be connected to the server. If a round
    has already started, every completely new player joins the battle. And if you
    need a break, you can make yourself a spectator in the settings at any time.]]

    local function draw_headline_button( player )

        if player.gui.top[ name_headline_button ] then player.gui.top[ name_headline_button ].destroy() end

        local element_button = player.gui.top.add( { type = 'sprite-button', name = name_headline_button, caption = '?', tooltip = 'Scenario Introduction' } )

        element_button.style.height = 38

        element_button.style.font = 'heading-1'

        element_button.style.font_color = { r = 0.5, g = 0.3, b = 0.99 }

    end

    local function draw_main_frame( player )

        if player.gui.center[ name_main_frame ] then player.gui.center[ name_main_frame ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = name_main_frame, caption = 'Scenario Introduction >> ' .. scenario_name, direction = 'vertical' } )

        local element_label = element_frame.add( { type = 'label', caption = scenario_introduction } )

        element_label.style.top_padding = 15

        element_label.style.single_line = false

        element_label.style.font = 'heading-2'

        element_label.style.font_color = { r = 0.7, g = 0.6, b = 0.99 }

        local element_flow = element_frame.add( { type = 'flow' } )

        element_flow.style.top_margin = 15

        element_flow.style.horizontal_align = 'right'

        element_flow.style.horizontally_stretchable = true

        element_flow.add( { type = 'button', name = name_main_button_close, style = 'rounded_button', caption = 'CLOSE' } )

    end

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        if event.element.valid and event.element.name == name_headline_button then

            if player.gui.center[ name_main_frame ] then

                if player.gui.center[ name_main_frame ].visible == true then

                    player.gui.center[ name_main_frame ].visible = false

                else

                    player.gui.center[ name_main_frame ].visible = true

                end

            else

                draw_main_frame( player )

            end

        end

        if event.element.valid and event.element.name == name_main_button_close then

            player.gui.center[ name_main_frame ].visible = false

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        draw_headline_button( player )

        if player.online_time == 0 then draw_main_frame( player ) end

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )
