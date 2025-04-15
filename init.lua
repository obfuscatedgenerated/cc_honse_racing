local obsi = require "obsi2"
local game_loop = require "game_loop"

-- this init file exists as the simplest way to initialise the game loop
-- you can use the functions in game_loop to read the game state, which can be useful for embedding the game
-- e.g. link to your gambling bet system
-- TODO: proper hooking?

function obsi.load()
    game_loop.setup()
end

function obsi.draw()
    game_loop.update()
end

obsi.init()
