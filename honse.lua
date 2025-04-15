local obsi = require "obsi2"

local GameState = require "game_state"
local Honse = require "honse_sprite"
local field = require "field"

local honses = {}

-- TODO: time limit
-- TODO: overlay details
-- TODO: hooks

local function respawn(honse)
    local spawn_x, spawn_y = field.spawn_bb:random_point()
    honse.winner = false
    honse.x = spawn_x
    honse.y = spawn_y
    honse.travel_x = 1
    honse.travel_y = 1

    return honse
end

local function respawn_all()
    for i = 1, #honses do
        local honse = honses[i]
        respawn(honse)
    end
end

function obsi.load()
    local green_honse = Honse.from_colour(colors.green)
    green_honse.name = "Green"
    table.insert(honses, green_honse)

    local blue_honse = Honse.from_colour(colors.blue)
    blue_honse.name = "Blue"
    table.insert(honses, blue_honse)

    local red_honse = Honse.from_colour(colors.red)
    red_honse.name = "Red"
    table.insert(honses, red_honse)

    local yellow_honse = Honse.from_colour(colors.yellow)
    yellow_honse.name = "Yellow"
    table.insert(honses, yellow_honse)

    respawn_all()
end

local function simulate_all(state)
    for i = 1, #honses do
        local honse = honses[i]
        honse:simulate(state, honses)
    end
end

local function apply_travel_all()
    for i = 1, #honses do
        local honse = honses[i]
        honse:apply_travel()
    end
end

local function draw_all()
    for i = 1, #honses do
        local honse = honses[i]
        honse:draw()
    end
end

local function check_winner()
    for i = 1, #honses do
        local honse = honses[i]
        if honse.winner then
            return honse
        end
    end

    return nil
end

local function check_oob_all()
    -- sometimes the oob detection in collision isnt enough, so respawn any horse that is very lost
    for i = 1, #honses do
        local honse = honses[i]
        if honse:check_oob() then
            respawn(honse)
        end
    end
end

local state = GameState.PLACE_BETS
local timer_start = obsi.timer.getTime()

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
        local time_left = math.ceil(10 - (obsi.timer.getTime() - timer_start))
        local text = "PLACE BETS... " .. time_left
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
        check_oob_all()
    end

    draw_all()

    local winner = check_winner()

    if winner and state ~= GameState.GOT_WINNER then
        -- one off transition
        timer_start = obsi.timer.getTime()
        state = GameState.GOT_WINNER
    end

    if state == GameState.GOT_WINNER then
        obsi.graphics.write("Winner: " .. winner.name, 1, 1)
        obsi.graphics.draw(winner.sprite, 1, 2)

        -- reset after 5 seconds
        if obsi.timer.getTime() - timer_start > 5 then
            state = GameState.PLACE_BETS
            timer_start = obsi.timer.getTime()
            
            respawn_all()
        end
    end

    if state == GameState.PLACE_BETS then
        -- if it's been 10 seconds since starting betting, end betting
        if obsi.timer.getTime() - timer_start > 10 then
            state = GameState.RACING
            timer_start = nil
        end
    end
end

obsi.init()
