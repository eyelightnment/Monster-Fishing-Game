Width, Height = 480, 360
Offset = 0
Fullscreen = false

TotalTime = 0
Horizon = Height / 3

function love.load()
    love.math.setRandomSeed(os.time())
    --print(os.time()) -- debug

    require("background") -- load other files
    require("assets")
    require("splash")
    require("ui")
    require("fish")
    require("critters")

    Scale = 2 -- x2 upscaling by default
    love.window.updateMode(Width*Scale, Height*Scale)
    love.graphics.setLineStyle("rough") -- turn off anti aliasing

    bgm.current = bgm.sea -- music
    bgm.current:play()

    notify("Press F11 for fullscreen - Click these boxes to close them.")
    notify("Filling the bar will catch the fish!")
    notify("Hold/release left mouse button to match fish height.")
    notify("Once fish bites, click once to start reeling.")
    notify("Welcome!, Click to cast line and wait for fish to bite..")

    -- settle the clouds beforehand
    for i = 1, 2000 do
        simulateClouds(0.5, Horizon)
    end

    -- set placeholder sprites
    for _, v in pairs(critters) do
        if v.sprite == nil then v.sprite = sprite.placeholder end
    end
end

function love.update(dt)
    --dt = dt / 2
    TotalTime = TotalTime + dt

    fishingLoop(dt)
    simulateClouds(dt, Horizon)
    simulateRod(dt)
    splash.simulate(dt)
end

function love.draw()
    local WindowWidth, WindowHeight = love.window.getMode()
    Scale = WindowHeight / Height -- window/render resolution ratio
    love.graphics.scale(Scale, Scale) -- upscale by ratio
    Offset = (WindowWidth / Scale - Width) / 2
    love.graphics.translate(Offset, 0) -- center the render (applied before scaling)

    drawScene.Ocean()
    ---[[
    splash.draw()
    local conditions = fishing.state == "reeling" or fishing.state == "fishing" or fishing.bobber ~= "idle"
    if conditions then
        drawBobber()
    end
    drawScene.Ocean(true)
    drawRod()
    if not conditions then
        drawBobber()
    end

    drawNotifications()
    if fishing.state == "reeling" then drawMinigame() end
    --]]

    -- black bars
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", -Offset, 0, Offset, Height) -- left
    love.graphics.rectangle("fill", Width, 0, Offset, Height) -- right
end

function love.keypressed(key, scancode, isrepeat)
	if key == "f11" then
		Fullscreen = not Fullscreen
		love.window.setFullscreen(Fullscreen)
    --[[ DEBUG KEYS
    elseif key == "d" then
        fishing.fishPerSecond = 10
        minigame.area = 1
        minigame.twin = 1
        print("debug activated")
    elseif key == "f" then
        --print(critterGacha().name)
        local count = {}
        for i = 1, 100000 do 
            local name = critterGacha().name
            if count[name] == nil then count[name] = 1
            else count[name] = count[name] + 1
            end
        end
        print("-- fishrates --")
        for k, v in pairs(count) do
            print(k..": "..(v/100000*100).."%")
        end
    elseif key == "n" then
        notify("Debug message.")
    --]]
	end
end

local heldButton = nil
function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- leftclicks
        local nopresses = true
        do -- buttons click logic
            local minz = 999
            local act = nil
            for _, v in pairs(buttons) do -- check for button presses
                if isPressed(x, y, v) then
                    if v.z < minz then -- change action if lower z found
                        act = v.action
                        minz = v.z
                        heldButton = v
                    end
                    nopresses = false
                end
            end
            if act then act() end
        end
        if nopresses then fishing.clicked = true end -- dont update when there's a button press
    --[[ debug splash test with right click
    else
        local xx, yy = screenSpaceToGame(x, y)
        splash.new(xx, yy, 16, 100, 24)
    --]]
    end
end
function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 then -- leftclicks
        if heldButton ~= nil then -- button could be deleted
            if isPressed(x, y, heldButton) then -- check if still in bound
                heldButton.release() -- do release action
            end
        end
    end
end
