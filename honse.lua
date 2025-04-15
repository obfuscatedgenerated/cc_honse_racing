local obsi = require "/lib/obsi2"

local GameState = require "game_state"
local field = require "field"
local BB = require "bb"

local TRANSPARENT = -1

local COLLIDE_DEBUG = false

local honse_template = obsi.graphics.newImage("honse_template.nfp")

local PHYSICS_MARGIN = 1 -- TODO: sep margin for walls and horse collision. walls best as 2, horse best as 0 or 1
local MAX_PENETRATION = 0.75
local BB_SHIFT = {
    x = 0,
    y = 0
}

local Honse = {}
Honse.mt = {}
Honse.prototype = {
    name = "",
    sprite = { {} },
    x = 1,
    y = 1,
    last_safe_x = 1,
    last_safe_y = 1,
    travel_x = 0,
    travel_y = 0,
    winner = false,
}

function Honse.new(o)
    setmetatable(o, Honse.mt)
    return o
end

local function get_colour_honse(colour)
    local new_honse = obsi.graphics.newBlankImage(honse_template.width, honse_template.height)
    for y = 1, #honse_template.data do
        for x = 1, #honse_template.data[y] do
            if honse_template.data[y][x] == colors.white then
                new_honse.data[y][x] = colour
            end
        end
    end

    return new_honse
end

function Honse.from_colour(colour)
    return Honse.new { sprite = get_colour_honse(colour) }
end

Honse.mt.__index = function(table, key)
    if key == "width" then return honse_template.width end
    if key == "height" then return honse_template.height end

    return Honse.prototype[key]
end

function Honse.prototype:draw()
    obsi.graphics.draw(self.sprite, self.x, self.y)
end

function Honse.prototype:apply_travel()
    self.x = self.x + self.travel_x
    self.y = self.y + self.travel_y
end

function Honse.prototype:get_bb()
    return BB.new {
        x0 = self.x + BB_SHIFT.x,
        y0 = self.y + BB_SHIFT.y,
        x1 = self.x + self.width + BB_SHIFT.x,
        y1 = self.y + self.height + BB_SHIFT.y
    }
end

function Honse.prototype:get_hitbox()
    return self:get_bb():get_expanded(PHYSICS_MARGIN, PHYSICS_MARGIN)
end

function Honse.prototype:get_vector_from(other)
    local other_x, other_y = other:get_bb():get_center()
    local x_diff = other_x - self.x
    local y_diff = other_y - self.y

    return x_diff, y_diff
end

function Honse.prototype:get_vector_to(other)
    local other_x, other_y = other:get_bb():get_center()
    local x_diff = self.x - other_x
    local y_diff = self.y - other_y

    return x_diff, y_diff
end

function Honse.prototype:check_oob()
    return self.x < 1 or self.y < 1 or self.x > field.sprite.width or self.y > field.sprite.height
end

function Honse.prototype:check_wall_collision()
    return self:get_hitbox():test_any_point(function(x, y)
        -- offscreen is always a collision
        if self:check_oob() then
            return true
        end

        local colour = field.read_colour(x, y)

        if colour ~= nil and colour ~= field.AIR_COLOUR and colour ~= TRANSPARENT then
            if colour == field.CARROT_COLOUR then
                self.winner = true
            end

            return true
        end
    end, honse_template.data)
end

function Honse.prototype:apply_wall_bounce()
    local hbox = self:get_hitbox()

    -- for each hit, compare position to the center and contribute to a bounce vector
    local center_x, center_y = hbox:get_center()
    local bounce_x = 0
    local bounce_y = 0

    local total_points = 0
    local total_collisions = 0

    hbox:for_each_point(function(x, y)
        total_points = total_points + 1

        local colour = field.read_colour(x, y)

        if colour ~= nil and colour ~= field.AIR_COLOUR and colour ~= TRANSPARENT then
            local x_diff = x - center_x
            local y_diff = y - center_y

            bounce_x = bounce_x + x_diff
            bounce_y = bounce_y + y_diff

            total_collisions = total_collisions + 1
        end
    end)

    -- if too many points collided, panic!
    if total_collisions / total_points > MAX_PENETRATION then
        self.x = self.last_safe_x
        self.y = self.last_safe_y
    end

    -- normalise the bounce vector
    local bounce_length = math.sqrt(bounce_x * bounce_x + bounce_y * bounce_y)
    if bounce_length > 0 then
        bounce_x = bounce_x / bounce_length
        bounce_y = bounce_y / bounce_length

        -- get the dot product of the bounce vector and the travel vector
        local dot = self.travel_x * bounce_x + self.travel_y * bounce_y

        -- reflect
        self.travel_x = self.travel_x - 2 * dot * bounce_x
        self.travel_y = self.travel_y - 2 * dot * bounce_y

        -- nudge along the normal to avoid sticking
        self.x = self.x - bounce_x * 0.5
        self.y = self.y - bounce_y * 0.5
    end
end

function Honse.prototype:check_and_apply_horse_collision(others)
    for i = 1, #others do
        local other = others[i]

        if other ~= self and self:get_hitbox():intersects(other:get_bb()) then
            if COLLIDE_DEBUG then
                obsi.graphics.write("horse colliding", 1, 2)
            end
            
            -- only apply my own bounce, the NEIGHbour can handle its own bouncing
            local x_diff, y_diff = self:get_vector_from(other)
            local x_diff_len = math.sqrt(x_diff * x_diff + y_diff * y_diff)

            if x_diff_len > 0 then
                x_diff = x_diff / x_diff_len
                y_diff = y_diff / x_diff_len

                -- get the dot product of the bounce vector and the travel vector
                local dot = self.travel_x * x_diff + self.travel_y * y_diff

                -- reflect
                self.travel_x = self.travel_x - 2 * dot * x_diff
                self.travel_y = self.travel_y - 2 * dot * y_diff

                -- nudge along the normal to avoid sticking
                self.x = self.x - x_diff * 0.5
                self.y = self.y - y_diff * 0.5
            end
        end
    end
end

function Honse.prototype:check_gate_collision()
    return self:get_hitbox():intersects(field.gate_bb)
end

function Honse.prototype:apply_gate_bounce()
    -- treat like a wall
    local hbox = self:get_hitbox()
    local center_x, center_y = hbox:get_center()

    local bounce_x = 0
    local bounce_y = 0

    local total_points = 0
    local total_collisions = 0

    hbox:for_each_point(function(x, y)
        total_points = total_points + 1

        local has_point = field.gate_bb:has_point(x, y)

        if has_point then
            local x_diff = x - center_x
            local y_diff = y - center_y

            bounce_x = bounce_x + x_diff
            bounce_y = bounce_y + y_diff

            total_collisions = total_collisions + 1
        end
    end)

    -- if too many points collided, panic!
    if total_collisions / total_points > MAX_PENETRATION then
        self.x = self.last_safe_x
        self.y = self.last_safe_y
    end

    -- normalise the bounce vector
    local bounce_length = math.sqrt(bounce_x * bounce_x + bounce_y * bounce_y)
    if bounce_length > 0 then
        bounce_x = bounce_x / bounce_length
        bounce_y = bounce_y / bounce_length

        -- get the dot product of the bounce vector and the travel vector
        local dot = self.travel_x * bounce_x + self.travel_y * bounce_y

        -- reflect
        self.travel_x = self.travel_x - 2 * dot * bounce_x
        self.travel_y = self.travel_y - 2 * dot * bounce_y

        -- nudge along the normal to avoid sticking
        self.x = self.x - bounce_x * 0.5
        self.y = self.y - bounce_y * 0.5
    end

    -- TODO: unite this logic with wall bounce
end

function Honse.prototype:simulate(state, others)
    -- if in place bets state, check gate collision
    local gate_collided = false
    if state == GameState.PLACE_BETS then
        if self:check_gate_collision() then
            gate_collided = true

            if COLLIDE_DEBUG then
                obsi.graphics.write("gate colliding", 1, 2)
            end

            -- apply gate bounce
            self:apply_gate_bounce()
        end
    end


    -- check for collision
    local wall_colliding = self:check_wall_collision()

    if not gate_collided and not wall_colliding then
        -- save the last safe position
        self.last_safe_x = self.x
        self.last_safe_y = self.y
    end

    if self.winner then
        if COLLIDE_DEBUG then
            obsi.graphics.write("winner", 1, 2)
        end

        return
    end

    if wall_colliding then
        if COLLIDE_DEBUG then
            obsi.graphics.write("wall colliding", 1, 2)
        end

        self:apply_wall_bounce()
    end

    self:check_and_apply_horse_collision(others)
end

return Honse
