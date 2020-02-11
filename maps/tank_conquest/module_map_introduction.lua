
    local event = require 'utils.event'

    local map_intro = [[                                                            - - - T A N K    C O N Q U E S T - - -

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

    local function draw_gui_intro_button( player )

        if player.gui.top[ 'draw_gui_intro_button' ] then return end

        local element_button = player.gui.top.add( { type = 'sprite-button', name = 'draw_gui_intro_button', caption = '?', tooltip = 'INTRO' } )

        element_button.style.width = 38

        element_button.style.height = 38

        element_button.style.font_color = { r = 0.5, g = 0.3, b = 0.99 }

        element_button.style.font = 'heading-1'

    end

    local function draw_gui_intro_frame( player )

        if player.gui.center[ 'draw_gui_intro_frame' ] then player.gui.center[ 'draw_gui_intro_frame' ].destroy() end

        local element_frame = player.gui.center.add( { type = 'frame', name = 'draw_gui_intro_frame', direction = 'vertical' } )

        element_frame = element_frame.add( { type = 'frame' } )

        local element_label = element_frame.add( { type = 'label', name = 'draw_gui_intro_content', caption = map_intro } )

        element_label.style.top_padding = 15

        element_label.style.single_line = false

        element_label.style.font = 'heading-2'

        element_label.style.font_color = { r = 0.7, g = 0.6, b = 0.99 }

    end

    local function on_gui_click( event )

        local player = game.players[ event.player_index ]

        if event.element.valid and event.element.name == 'draw_gui_intro_content' then player.gui.center[ 'draw_gui_intro_frame' ].destroy() return end

        if event.element.valid and event.element.name == 'draw_gui_intro_button' then

            if player.gui.center[ 'draw_gui_intro_frame' ] then player.gui.center[ 'draw_gui_intro_frame' ].destroy() else draw_gui_intro_frame( player ) end

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_player_joined_game( event )

        local player = game.players[ event.player_index ]

        draw_gui_intro_button( player )

        if player.online_time == 0 then draw_gui_intro_frame( player ) end

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )
