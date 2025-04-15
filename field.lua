local obsi = require "obsi2"

local sprite = obsi.graphics.newImage("field.orli")

local AIR_COLOUR = colors.white
local CARROT_COLOUR = colors.orange
local TRANSPARENT = -1

local READ_SHIFT = {
    x = 1,
    y = 1
}

local function read_colour(x, y)
    local col = sprite.data[math.floor(y) + READ_SHIFT.y]
    if col == nil then return nil end

    return col[math.floor(x) + READ_SHIFT.x]
end

return {
    sprite = sprite,
    AIR_COLOUR = AIR_COLOUR,
    CARROT_COLOUR = CARROT_COLOUR,
    TRANSPARENT = TRANSPARENT,
    read_colour = read_colour,
}