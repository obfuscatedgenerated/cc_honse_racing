local obsi = require("obsi2")

local honse_template = obsi.graphics.newImage("honse_template.nfp")
local field = obsi.graphics.newImage("field.orli")

local FIELD_AIR = colors.white

local function get_colour_honse(colour)
    local new_honse = obsi.graphics.newBlankImage(honse_template.width, honse_template.height)
    for y=1, #honse_template.data do
        for x=1, #honse_template.data[y] do
            if honse_template.data[y][x] == colors.white then
                new_honse.data[y][x] = colour
            end
        end
    end
    
    return new_honse
end

local function read_field_colour(x, y)
    local col = field.data[y]
    if col == nil then return nil end

    return col[x]
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

local BB = {}
BB.mt = {}
BB.prototype = {
    x0 = 0,
    y0 = 0,
    x1 = 0,
    y1 = 0
}

function BB.new(o)
    setmetatable(o, BB.mt)
    return o
end

function BB.from_coords(x0, y0, x1, y1)
    return BB.new{x0=x0, y0=y0, x1=x1, y1=y1}
end

function BB.mt.__index(table, key)
    if key == "width" then return table.x1 - table.x0 end
    if key == "height" then return table.y1 - table.y0 end

    return BB.prototype[key]
end

function BB.prototype:copy()
    return BB.new{self.x0, self.y0, self.x1, self.y1}
end

function BB.prototype:intersects(other)
    return not (self.x0 > other.x1 or self.x1 < other.x0 or self.y0 > other.y1 or self.y1 < other.y0)
end

function BB.prototype:contains(other)
    return self.x0 <= other.x0 and self.y0 <= other.y0 and self.x1 >= other.x1 and self.y1 >= other.y1
end

function BB.prototype:contains_point(x, y)
    return x >= self.x0 and x <= self.x1 and y >= self.y0 and y <= self.y1
end

function BB.prototype:expand(x, y)
    self.x0 = self.x0 - x
    self.y0 = self.y0 - y
    self.x1 = self.x1 + x
    self.y1 = self.y1 + y
end

function BB.prototype:get_expanded(x, y)
    return BB.new{
        x0 = self.x0 - x,
        y0 = self.y0 - y,
        x1 = self.x1 + x,
        y1 = self.y1 + y
    }
end

function BB.prototype:get_center()
    return (self.x0 + self.x1) / 2, (self.y0 + self.y1) / 2
end

-- ignore masks will ignore any points with a non transparent value
-- the mask is scaled to the bounding box

function BB.prototype:for_each_point(func, ignore_mask)
    for x = self.x0, self.x1 do
        for y = self.y0, self.y1 do
            if not ignore_mask then
                func(x, y)
            else
                local x_in_bbox = x - self.x0 + 1
                local y_in_bbox = y - self.y0 + 1

                -- any mask value that isnt -1 (transparent) is ignored
                if ignore_mask[y_in_bbox] and ignore_mask[y_in_bbox][x_in_bbox] and ignore_mask[y_in_bbox][x_in_bbox] == -1 then
                    func(x, y)
                end
            end
        end
    end
end

function BB.prototype:test_each_point(func, ignore_mask)
    for x = self.x0, self.x1 do
        for y = self.y0, self.y1 do
            if not ignore_mask then
                if func(x, y) then
                    return true
                end
            else
                local x_in_bbox = x - self.x0 + 1
                local y_in_bbox = y - self.y0 + 1

                -- any mask value that isnt -1 (transparent) is ignored
                if ignore_mask[y_in_bbox] and ignore_mask[y_in_bbox][x_in_bbox] and ignore_mask[y_in_bbox][x_in_bbox] == -1 then
                    if func(x, y) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function Honse.prototype:get_bb()
    return BB.new{
        x0 = self.x,
        y0 = self.y,
        x1 = self.x + self.width,
        y1 = self.y + self.height
    }
end

local green_honse
local blue_honse

function obsi.load()
    green_honse = Honse.from_colour(colors.green)
    green_honse.x = 5
    green_honse.y = 10

    blue_honse = Honse.from_colour(colors.blue)
    blue_honse.x = 20
    blue_honse.y = 20
end

function obsi.draw()
    obsi.graphics.draw(field, 1, 1)

    local green_hitbox = green_honse:get_bb():get_expanded(1, 1)
    local colliding = green_hitbox:test_each_point(function(x, y)
        local colour = read_field_colour(x, y)

        if colour ~= nil and colour ~= FIELD_AIR and colour ~= -1 then
            return true
        end
    end, honse_template.data)

    -- TODO: check horse and other collisions

    if colliding then
        obsi.graphics.write("colliding", 1, 1)
        -- TODO: bounce
    end

    green_honse.x = green_honse.x + 1

    green_honse:draw()
    blue_honse:draw()
end

obsi.init()
