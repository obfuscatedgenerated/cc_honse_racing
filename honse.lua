local obsi = require "obsi2"

local GameState = require "game_state"
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

function simulate_all(state)
    for i = 1, #honses do
        local honse = honses[i]
        honse:simulate(state, honses)
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

local state = GameState.PLACE_BETS
local bets_start = obsi.timer.getTime()

function obsi.draw()
    obsi.graphics.draw(field.sprite, 1, 1)

    -- draw gate text if gate should be visible
    if state == GameState.PLACE_BETS then
        -- draw gate rect
        obsi.graphics.setForegroundColor(colors.white)
        obsi.graphics.rectangle("fill", field.gate_bb.x0, field.gate_bb.y0, field.gate_bb.width, field.gate_bb.height)

        -- draw gate letters
        obsi.graphics.setForegroundColor(colors.black)
        obsi.graphics.setBackgroundColor(colors.white)
        local tx0, ty0 = obsi.graphics.pixelToTermCoordinates(field.gate_bb.x0, field.gate_bb.y0)
        ty0 = ty0 + 1
        obsi.graphics.write("G", tx0, ty0)
        obsi.graphics.write("A", tx0, ty0 + 1)
        obsi.graphics.write("T", tx0, ty0 + 2)
        obsi.graphics.write("E", tx0, ty0 + 3)

        -- draw red place bets window showing time
        obsi.graphics.setForegroundColor(colors.white)
        obsi.graphics.setBackgroundColor(colors.red)
        local time_left = math.ceil(10 - (obsi.timer.getTime() - bets_start))
        local text = "PLACE BETS IN... " .. time_left
        if time_left < 1 then text = "GO!" end
        local text_width = #text
        local text_x = field.center.x - math.floor(text_width / 2)
        obsi.graphics.write(text, text_x, field.center.y)

        -- revert colours
        obsi.graphics.setForegroundColor(colors.white)
        obsi.graphics.setBackgroundColor(colors.black)
    end

    if state ~= GameState.GOT_WINNER then
        simulate_all(state)
        apply_travel_all()
    end

    draw_all()

    local winner = check_winner()

    if winner then
        state = GameState.GOT_WINNER

        obsi.graphics.write("Winner: " .. winner.name, 1, 1)
        obsi.graphics.draw(winner.sprite, 1, 2)
    end

    if state == GameState.PLACE_BETS then
        -- if it's been 10 seconds since starting betting, end betting
        if obsi.timer.getTime() - bets_start > 10 then
            state = GameState.RACING
            bets_start = nil
        end
    end
end

obsi.init()
