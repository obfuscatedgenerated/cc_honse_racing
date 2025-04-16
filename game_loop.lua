local obsi = require "/lib/obsi2"

local GameState = require "game_state"
local Honse = require "honse"
local field = require "field"

local honses = {}

-- TODO: time limit
-- TODO: overlay details

local hooks = {}

-- check all calls to run_hooks to see hook names and arguments
-- hooks are ran sequentially in the added order, and block the game loop until completed
-- dispatch a coroutine if this is not intended
local function add_hook(name, func)
    if not hooks[name] then
        hooks[name] = {}
    end

    table.insert(hooks[name], func)
end

local function run_hooks(name, ...)
    if not hooks[name] then return end

    for i = 1, #hooks[name] do
        local hook = hooks[name][i]
        hook(...)
    end
end

local function respawn(honse)
    run_hooks("pre-respawn", honse)

    local spawn_x, spawn_y = field.spawn_bb:random_point()
    honse.winner = false
    honse.x = spawn_x
    honse.y = spawn_y
    honse.travel_x = 1
    honse.travel_y = 1

    run_hooks("post-respawn", honse)

    return honse
end

local function respawn_all()
    run_hooks("pre-respawn_all")

    for i = 1, #honses do
        local honse = honses[i]
        respawn(honse)
    end

    run_hooks("post-respawn_all")
end

local function setup()
    run_hooks("pre-setup")

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

    run_hooks("post-setup")
end

local function simulate_all(state)
    run_hooks("pre-simulate_all", state)

    for i = 1, #honses do
        local honse = honses[i]

        run_hooks("pre-simulate", honse, state)
        honse:simulate(state, honses)
        run_hooks("post-simulate", honse, state)
    end

    run_hooks("post-simulate_all", state)
end

local function apply_travel_all()
    run_hooks("pre-apply_travel_all")

    for i = 1, #honses do
        local honse = honses[i]

        run_hooks("pre-apply_travel", honse)
        honse:apply_travel()
        run_hooks("post-apply_travel", honse)
    end

    run_hooks("post-apply_travel_all")
end

local function draw_all()
    run_hooks("pre-draw_all")

    for i = 1, #honses do
        local honse = honses[i]

        run_hooks("pre-draw", honse)
        honse:draw()
        run_hooks("post-draw", honse)
    end

    run_hooks("post-draw_all")
end

local function check_winner()
    run_hooks("pre-check_winner")

    for i = 1, #honses do
        local honse = honses[i]
        if honse.winner then
            run_hooks("post-check_winner", honse)
            return honse
        end
    end

    run_hooks("post-check_winner", nil)
    return nil
end

local function check_oob_all()
    run_hooks("pre-check_oob_all")

    -- sometimes the oob detection in collision isnt enough, so respawn any horse that is very lost
    for i = 1, #honses do
        local honse = honses[i]

        run_hooks("pre-check_oob", honse)
        if honse:check_oob() then
            respawn(honse)
        end
        run_hooks("post-check_oob", honse)
    end

    run_hooks("post-check_oob_all")
end

local state = GameState.PLACE_BETS
local timer_start = obsi.timer.getTime()

local function update()
    run_hooks("pre-update")

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
        local text_x = field.alert_center.x - math.floor(text_width / 2)
        obsi.graphics.write(text, text_x, field.alert_center.y)

        -- revert colours
        obsi.graphics.setForegroundColor(colors.white)
        obsi.graphics.setBackgroundColor(colors.black)
    end

    if state ~= GameState.GOT_WINNER then
        run_hooks("pre-simuation")

        simulate_all(state)
        apply_travel_all()
        check_oob_all()

        run_hooks("post-simulation")
    end

    draw_all()

    local winner = check_winner()

    if winner and state ~= GameState.GOT_WINNER then
        -- one off transition
        run_hooks("once-got_winner")
        timer_start = obsi.timer.getTime()
        state = GameState.GOT_WINNER
    end

    if state == GameState.GOT_WINNER then
        local text_x, text_y = obsi.graphics.pixelToTermCoordinates(field.right_margin_bb.x0, field.right_margin_bb.y0)
        obsi.graphics.write("Winner: " .. winner.name, text_x, text_y + 1)

        -- reset after 5 seconds
        if obsi.timer.getTime() - timer_start > 5 then
            run_hooks("pre-reset")

            state = GameState.PLACE_BETS
            timer_start = obsi.timer.getTime()
            
            respawn_all()

            run_hooks("post-reset")
        end
    end

    if state == GameState.PLACE_BETS then
        -- if it's been 10 seconds since starting betting, end betting
        if obsi.timer.getTime() - timer_start > 10 then
            run_hooks("once-end_betting")

            state = GameState.RACING
            timer_start = nil
        end
    end

    -- now is a good time to draw custom stuff in order to delay firing post-update until the custom drawing is complete
    run_hooks("once-draw_custom")

    run_hooks("post-update")
end

local function get_state()
    return state
end

return {
    setup=setup,
    update=update,
    get_state=get_state,
    check_winner=check_winner,
    add_hook=add_hook,
}
