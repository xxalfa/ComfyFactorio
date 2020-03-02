
    local event = require 'utils.event'

    local gui = require 'utils.gui'

    local name_button_headline = gui.uid_name()

    local name_frame_main = gui.uid_name()

    local name_button_close = gui.uid_name()

    local scenario_name = 'Tank Conquest'

    local scenario_introduction = [[
    When the round is running, the ticket overview is shown in the header. Your objective
    is to defend your team's tickets and withdraw the tickets from the opposing team as
    quickly as possible.

    There are two ways to withdraw the tickets from the opposing team. First, by killing
    the player and second, by taking the spots. A spot withdraw 0.05 tickets per second
    from the opposing team.

    The battlefield has two special features: First, there is a point of interest in the
    north and south. And second, there are loot boxes scattered throughout the battlefield.

    PvP battles and the conquest of the spots are the deciding factor to win the round.

    The battlefield is created when at least two players are online.

    There is no biter evolution from pollution, time or destruction.

    Chat settings can be set with @all or @team. Default: @all]]

    local function draw_button_headline( player )

        if player.gui.top[ name_button_headline ] then player.gui.top[ name_button_headline ].destroy() end

        local element_button = player.gui.top.add( { type = 'sprite-button', name = name_button_headline, caption = '?', tooltip = 'Scenario Introduction' } )

        element_button.style.height = 38

        element_button.style.font = 'heading-1'

        element_button.style.font_color = { r = 0.5, g = 0.3, b = 0.99 }

    end

    local function draw_frame_main( player )

        if player.gui.center[ name_frame_main ] then player.gui.center[ name_frame_main ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = name_frame_main, caption = 'Scenario Introduction >> ' .. scenario_name, direction = 'vertical' } )

        local element_label = element_frame.add( { type = 'label', caption = scenario_introduction } )

        element_label.style.top_padding = 15

        element_label.style.single_line = false

        element_label.style.font = 'heading-2'

        element_label.style.font_color = { r = 0.7, g = 0.6, b = 0.99 }

        local element_flow = element_frame.add( { type = 'flow' } )

        element_flow.style.top_margin = 15

        element_flow.style.horizontal_align = 'right'

        element_flow.style.horizontally_stretchable = true

        element_flow.add( { type = 'button', name = name_button_close, style = 'rounded_button', caption = 'CLOSE' } )

    end

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        if event.element.valid and event.element.name == name_button_headline then

            if player.gui.center[ name_frame_main ] then

                if player.gui.center[ name_frame_main ].visible == true then

                    player.gui.center[ name_frame_main ].visible = false

                else

                    player.gui.center[ name_frame_main ].visible = true

                end

            else

                draw_frame_main( player )

            end

        end

        if event.element.valid and event.element.name == name_button_close then

            player.gui.center[ name_frame_main ].visible = false

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        draw_button_headline( player )

        if player.online_time == 0 then draw_frame_main( player ) end

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )
