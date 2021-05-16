
    global.on_tick_schedule = {}

    function schedule_execute_on_tick( tick, func, args )

        if not global.on_tick_schedule then global.on_tick_schedule = {} end

        if not global.on_tick_schedule[ tick ] then global.on_tick_schedule[ tick ] = {} end

        table.insert( global.on_tick_schedule[ tick ], { func = func, args = args } )

    end

    local function on_init()

        if not global.on_tick_schedule then global.on_tick_schedule = {} end

    end

    local function on_tick()

        if not global.on_tick_schedule[ game.tick ] then return end

        for _, schedule in pairs( global.on_tick_schedule[ game.tick ] ) do

            schedule.func( unpack( schedule.args ) )

        end

        global.on_tick_schedule[ game.tick ] = nil

    end

    local Event = require 'utils.event'

    Event.on_init( on_init )

    Event.add( defines.events.on_tick, on_tick )
