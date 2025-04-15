local obsi = require "/lib/obsi2"

local BB = {}
BB.mt = {}
BB.prototype = {
    x0 = 0,
    y0 = 0,
    x1 = 0,
    y1 = 0
}

local TRANSPARENT = -1

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

function BB.prototype:debug_draw()
    obsi.graphics.setForegroundColor(colors.red)
    obsi.graphics.rectangle("fill", self.x0, self.y0, self.width, self.height)
    obsi.graphics.setForegroundColor(colors.white)
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

function BB.prototype:random_point()
    local x = math.random(self.x0, self.x1)
    local y = math.random(self.y0, self.y1)

    return x, y
end

function BB.prototype:has_point(x, y)
    return x >= self.x0 and x <= self.x1 and y >= self.y0 and y <= self.y1
end

return BB
