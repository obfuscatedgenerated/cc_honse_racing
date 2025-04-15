local obsi = require "obsi2"

local Honse = require "honse_sprite"
local field = require "field"

local honses = {}

-- TODO: randomisation
-- TODO: start cage
-- TODO: bets
-- TODO: time limit

function obsi.load()
    local green_honse = Honse.from_colour(colors.green)
    green_honse.name = "Green"
    local spawn_x, spawn_y = field.spawn_bb:random_point()
    green_honse.x = 25
    green_honse.y = 10
    green_honse.travel_x = 1
    green_honse.travel_y = 1

    table.insert(honses, green_honse)

    local blue_honse = Honse.from_colour(colors.blue)
    blue_honse.name = "Blue"
    local spawn_x, spawn_y = field.spawn_bb:random_point()
    blue_honse.x = spawn_x
    blue_honse.y = spawn_y
    blue_honse.travel_x = 1
    blue_honse.travel_y = 1

    table.insert(honses, blue_honse)

    local red_honse = Honse.from_colour(colors.red)
    red_honse.name = "Red"
    local spawn_x, spawn_y = field.spawn_bb:random_point()
    red_honse.x = spawn_x
    red_honse.y = spawn_y
    red_honse.travel_x = 1
    red_honse.travel_y = 1

    table.insert(honses, red_honse)
end

function simulate_all()
    for i = 1, #honses do
        local honse = honses[i]
        honse:simulate(honses)
    end
end

function apply_travel_all()
    for i = 1, #honses do
        local honse = honses[i]
        honse:apply_travel()
    end
end

function draw_all()
    for i = 1, #honses do
        local honse = honses[i]
        honse:draw()
    end
end

function check_winner()
    for i = 1, #honses do
        local honse = honses[i]
        if honse.winner then
            return honse
        end
    end

    return nil
end

local running = true

function obsi.draw()
    obsi.graphics.draw(field.sprite, 1, 1)
    field.gate_bb:debug_draw()

    if running then
        simulate_all()
        apply_travel_all()
    end

    draw_all()

    local winner = check_winner()

    if winner then
        running = false

        obsi.graphics.write("Winner: " .. winner.name, 1, 1)
        obsi.graphics.draw(winner.sprite, 1, 2)
    end
end

obsi.init()
