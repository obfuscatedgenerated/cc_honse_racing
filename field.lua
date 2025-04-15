local obsi = require "obsi2"

local BB = require "bb"

local sprite = obsi.graphics.newImage("field.orli")

local AIR_COLOUR = colors.white
local CARROT_COLOUR = colors.orange

local READ_SHIFT = {
    x = 1,
    y = 1
}

local spawn_bb = BB.new{
    x0 = 25,
    y0 = 10,
    x1 = 45,
    y1 = 20
}

local gate_bb = BB.new{
    x0 = 50,
    y0 = 9,
    x1 = 55,
    y1 = 22
}

local function read_colour(x, y)
    local col = sprite.data[math.floor(y) + READ_SHIFT.y]
    if col == nil then return nil end

    return col[math.floor(x) + READ_SHIFT.x]
end

local center = {
    x = math.floor(sprite.width / 4),
    y = math.floor(sprite.height / 5)
}

return {
    sprite = sprite,
    center = center,
    spawn_bb = spawn_bb,
    gate_bb = gate_bb,
    AIR_COLOUR = AIR_COLOUR,
    CARROT_COLOUR = CARROT_COLOUR,
    read_colour = read_colour,
}