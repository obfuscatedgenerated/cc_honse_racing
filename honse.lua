local obsi = require "obsi2"

local Honse = require "honse_sprite"
local field = require "field"

local green_honse
local blue_honse

function obsi.load()
    green_honse = Honse.from_colour(colors.green)
    green_honse.x = 10
    green_honse.y = 10
    green_honse.travel_x = 1
    green_honse.travel_y = 1

    blue_honse = Honse.from_colour(colors.blue)
    blue_honse.x = 20
    blue_honse.y = 20
end

function obsi.draw()
    obsi.graphics.draw(field.sprite, 1, 1)

    green_honse:simulate()
    blue_honse:simulate()
    
    green_honse:draw()
    blue_honse:draw()
end

obsi.init()
