local obsi = require("obsi2")

local honse_template = obsi.graphics.newImage("honse_template.nfp")
local field = obsi.graphics.newImage("field.orli")

local FIELD_AIR = colors.white
local TRANSPARENT = -1

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
    y = 1,
    travel_x = 0,
    travel_y = 0,
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

function Honse.prototype:apply_travel()
    self.x = self.x + self.travel_x
    self.y = self.y + self.travel_y
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

                -- any mask value that isnt transparent is ignored
                if ignore_mask[y_in_bbox] and ignore_mask[y_in_bbox][x_in_bbox] and ignore_mask[y_in_bbox][x_in_bbox] == TRANSPARENT then
                    func(x, y)
                end
            end
        end
    end
end

function BB.prototype:test_any_point(func, ignore_mask)
    for x = self.x0, self.x1 do
        for y = self.y0, self.y1 do
            if not ignore_mask then
                if func(x, y) then
                    return true
                end
            else
                local x_in_bbox = x - self.x0 + 1
                local y_in_bbox = y - self.y0 + 1

                -- any mask value that isnt TRANSPARENT (transparent) is ignored
                if ignore_mask[y_in_bbox] and ignore_mask[y_in_bbox][x_in_bbox] and ignore_mask[y_in_bbox][x_in_bbox] == TRANSPARENT then
                    if func(x, y) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function BB.prototype:test_all_points(func, ignore_mask)
    local results = {}

    for x = self.x0, self.x1 do
        for y = self.y0, self.y1 do
            if not ignore_mask then
                results[x] = func(x, y)
            else
                local x_in_bbox = x - self.x0 + 1
                local y_in_bbox = y - self.y0 + 1

                -- any mask value that isnt transparent is ignored
                if ignore_mask[y_in_bbox] and ignore_mask[y_in_bbox][x_in_bbox] and ignore_mask[y_in_bbox][x_in_bbox] == TRANSPARENT then
                    results[x] = func(x, y)
                else
                    results[x] = nil
                end
            end
        end
    end

    return results
end

-- TODO: way to test only on edges, all points might be overkill

function BB.prototype:for_each_corner(func)
    func(self.x0, self.y0)
    func(self.x1, self.y0)
    func(self.x0, self.y1)
    func(self.x1, self.y1)
end

function BB.prototype:test_any_corner(func)
    if func(self.x0, self.y0) then return true end
    if func(self.x1, self.y0) then return true end
    if func(self.x0, self.y1) then return true end
    if func(self.x1, self.y1) then return true end

    return false
end

function BB.prototype:test_all_corners(func)
    return {
        tl=func(self.x0, self.y0),
        tr=func(self.x1, self.y0),
        bl=func(self.x0, self.y1),
        br=func(self.x1, self.y1)
    }
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
    green_honse.x = 10
    green_honse.y = 10
    green_honse.travel_x = 1
    green_honse.travel_y = 1

    blue_honse = Honse.from_colour(colors.blue)
    blue_honse.x = 20
    blue_honse.y = 20
end

function obsi.draw()
    obsi.graphics.draw(field, 1, 1)

    -- check for collision
    local green_hitbox = green_honse:get_bb():get_expanded(1, 1)
    local colliding = green_hitbox:test_any_point(function(x, y)
        local colour = read_field_colour(x, y)

        if colour ~= nil and colour ~= FIELD_AIR and colour ~= TRANSPARENT then
            return true
        end
    end, honse_template.data)

    -- TODO: check horse and other collisions

    if colliding then
        obsi.graphics.write("colliding", 1, 1)

        -- for each hit, compare position to the center and contribute to a bounce vector
        local center_x, center_y = green_hitbox:get_center()
        local bounce_x = 0
        local bounce_y = 0
        local panic = true

        green_hitbox:for_each_point(function(x, y)
            local colour = read_field_colour(x, y)

            if colour ~= nil and colour ~= FIELD_AIR and colour ~= TRANSPARENT then
                local x_diff = x - center_x
                local y_diff = y - center_y

                bounce_x = bounce_x + x_diff
                bounce_y = bounce_y + y_diff
            else 
                panic = false
            end
        end)

        -- if all points collided, panic!
        if panic then
            -- TODO: add panic behaviour
        end

        -- normalise the bounce vector
        local bounce_length = math.sqrt(bounce_x * bounce_x + bounce_y * bounce_y)
        if bounce_length > 0 then
            bounce_x = bounce_x / bounce_length
            bounce_y = bounce_y / bounce_length

            -- get the dot product of the bounce vector and the travel vector
            local dot = green_honse.travel_x * bounce_x + green_honse.travel_y * bounce_y

            -- reflect
            green_honse.travel_x = green_honse.travel_x - 2 * dot * bounce_x
            green_honse.travel_y = green_honse.travel_y - 2 * dot * bounce_y
        end
    end

    green_honse:apply_travel()
    blue_honse:apply_travel()

    green_honse:draw()
    blue_honse:draw()
end

obsi.init()
