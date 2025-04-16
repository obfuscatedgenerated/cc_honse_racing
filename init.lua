local obsi = require "/lib/obsi2"
local game_loop = require "game_loop"

-- this init file exists as the simplest way to initialise the game loop
-- you can use the functions in game_loop to read the game state, which can be useful for embedding the game
-- e.g. link to your gambling bet system

-- you can also use hooks with the game_loop.add_hook function. read the game_loop file
-- to find all hook invocations with run_hooks
-- you still need to run the game loop with code like this, but you have the opportuinty to add hooks first

function obsi.load()
    game_loop.setup()
end

function obsi.draw()
    game_loop.update()
end

obsi.init()
