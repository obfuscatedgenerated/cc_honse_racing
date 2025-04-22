local obsi = require "/lib/obsi2"
local game_loop = require "game_loop"

-- notice the once-got_winner hook being set up during startup!
-- this will fire an event that can be yielded for with os.pullEvent("honse_winner")

function on_winner(winner)
    os.queueEvent("honse_winner", winner)
end

function obsi.load()
    game_loop.add_hook("once-got_winner", on_winner)

    game_loop.setup()
end

function obsi.draw()
    game_loop.update()
end

obsi.init()
