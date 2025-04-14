local obsi = require("obsi2")

local honse_template

function get_colour_honse(colour)
    local new_honse = obsi.graphics.newBlankImage(honse_template.width, honse_template.height)
    for x=1, #honse_template.data do
        for y=1, #honse_template.data[x] do
            if honse_template.data[x][y] == colors.white then
                new_honse.data[x][y] = colour
            end
        end
    end
    
    return new_honse
end

local Honse = {}
Honse.mt = {}
Honse.prototype = {
    gfx = {{}},
    x = 1,
    y = 1
}

function Honse.new(o)
    setmetatable(o, Honse.mt)
    return o
end

function Honse.from_colour(colour)
    return Honse.new{gfx=get_colour_honse(colour)}
end

Honse.mt.__index = function (table, key)
    if key == "width" then return honse_template.width end
    if key == "height" then return honse_template.height end

    return Honse.prototype[key]
end

function Honse.prototype:draw()
    obsi.graphics.draw(self.gfx, self.x, self.y)
end

function Honse.prototype:get_bb()
    return {
        x0 = self.x,
        y0 = self.y,
        x1 = self.x + self.width,
        y1 = self.y + self.height
    }
end

local green_honse
local blue_honse

function obsi.load()
    honse_template = obsi.graphics.newImage("honse_template.nfp")

    green_honse = Honse.from_colour(colors.green)

    blue_honse = Honse.from_colour(colors.blue)
    blue_honse.x = 10
end

function obsi.draw()
    green_honse:draw()
    blue_honse:draw()
end

obsi.init()
