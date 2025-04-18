local obsi = require "/lib/obsi2"

local BB = require "bb"

local sprite = obsi.graphics.newImage("field.orli")

local AIR_COLOUR = colors.white
local CARROT_COLOUR = colors.orange

local READ_SHIFT = {
    x = 1,
    y = 1
}

local field_bb = BB.new{
    x0 = 1,
    y0 = 1,
    x1 = sprite.width - 34, -- adjust for right side margin
    y1 = sprite.height
}

-- designed as the area to draw custom messages
local right_margin_bb = BB.new{
    x0 = sprite.width - 34,
    y0 = 1,
    x1 = sprite.width,
    y1 = sprite.height
}

local spawn_bb = BB.new{
    x0 = 10,
    y0 = 10,
    x1 = 30,
    y1 = 20
}

local gate_bb = BB.new{
    x0 = 35,
    y0 = 9,
    x1 = 40,
    y1 = 22
}

local function read_colour(x, y)
    local col = sprite.data[math.floor(y) + READ_SHIFT.y]
    if col == nil then return nil end

    return col[math.floor(x) + READ_SHIFT.x]
end

local alert_center = {
    x = math.floor(sprite.width / 5),
    y = math.floor(sprite.height / 5) - 1
}

return {
    sprite = sprite,
    alert_center = alert_center,
    bb = field_bb,
    right_margin_bb = right_margin_bb,
    spawn_bb = spawn_bb,
    gate_bb = gate_bb,
    AIR_COLOUR = AIR_COLOUR,
    CARROT_COLOUR = CARROT_COLOUR,
    read_colour = read_colour,
}