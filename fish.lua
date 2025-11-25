local hook = {} -- physics container for bobber

fishing = {} -- table for storing related variables
fishing.fishPerSecond = 1/6 -- expected amount of fishes caught per second
fishing.timer = 0
fishing.step = 0.4 -- check every (step) seconds for cathches
fishing.state = "idle"
fishing.clicked = false -- clicked before this step
fishing.biting = 0 -- biting timer
fishing.bobber = "idle" -- bobber state

function fishingLoop(dt)
    -- TODO maybe calculate fishPerSecond at the start accornding to variables

    if fishing.state == "idle" then
        --simulate bobber touching water, only proceed when it does
        if fishing.clicked and fishing.bobber == "idle" then -- cast bobber
            fishing.bobber = "falling" -- wait for physics to resolve
            hook.vx = hook.vx/2 + love.math.random(Width*0.5, Width*0.7) -- throw
            hook.vy = hook.vy/2 - love.math.random(Width*0.4, Width*0.6)
        elseif fishing.clicked and fishing.bobber == "falling" then -- cancel cast
            fishing.bobber = "idle"
        elseif fishing.bobber == "landed" then -- only proceed after bobber touches water
            fishing.state = "fishing" -- next state
            fishing.bobber = "idle" -- reset bobber state
            fishing.timer = 0 -- reset just in case
            sfx.cast:play() -- sfx
            splash.new(hook.x, hook.y, 8, 50, 24) -- splash vfx small
        end
    elseif fishing.state == "fishing" then
        if fishing.clicked then
            if fishing.biting <= 0 then -- fish wasnt biting when clicked
                fishing.state = "idle" -- go back to start
                sfx.recall:play()
            else -- fish is biting
                fishing.state = "reeling" -- start minigame
                fishingGacha() -- setup minigame
                sfx.biting:stop()
                sfx.hit:play()
                sfx.reeling:play()
            end
            fishing.biting = 0 -- reset flag
        else -- check if fish bites this frame
            if fishing.biting > 0 then fishing.biting = fishing.biting - dt -- already biting
            elseif fishing.biting < 0 then fishing.biting = 0 -- reset flag
            else
                while fishing.timer > fishing.step do -- fps might be lower than step
                    fishing.timer = fishing.timer - fishing.step
                    local fishPerStep = fishing.fishPerSecond * fishing.step
                    if love.math.random() < fishPerStep then -- biting
                        fishing.biting = 1.2 -- give the player a second of reaction time
                        splash.new(hook.x, hook.y, 16, 100, 24) -- splash vfx big
                        hook.vy = hook.vy + 350 -- tug
                        sfx.biting:play()
                        break -- cant catch more than one
                    elseif love.math.random() < 1.5 * fishPerStep then -- baiting player
                        hook.vy = hook.vy + 60 -- mini tug
                    end
                end
                fishing.timer = fishing.timer + dt
            end
        end
    elseif fishing.state == "reeling" then
        fishing.state = fishingMinigame(dt) -- the function decides the next state
        if fishing.state ~= "reeling" then sfx.reeling:stop() end
        if fishing.state == "caught" then -- transition
            local fish = minigame.fish
            local level = minigame.fishlevel
            notify("Caught a lv "..level.." "..fish.name.."!")
            fishing.timer = 1 -- display catch screen for at least this much time
        end
        -- random splash vfx
        if love.math.random() < dt * 8 then
            splash.new(hook.x, getSurfaceHeight(hook.x), 1, 50, 24) -- splash vfx small
        end
    elseif fishing.state == "caught" then
        fishing.timer = fishing.timer - dt
        if fishing.clicked and fishing.timer <= 0 then fishing.state = "idle" end -- wait until click
    else
        print("DEBUG invalid fishing state") --debug
    end

    fishing.clicked = false -- already processed this click
end

minigame = {}
-- static values
minigame.start = 0.15 -- starting progress
minigame.acc = 1
minigame.area = 0.35 -- catch area
minigame.bounce = 0.5 -- bar bounciness
minigame.gracetime = 1.5 -- progress doesnt decrease at start
minigame.twin = 6 -- seconds to win
minigame.tlose = 5 -- seconds to lose
-- depends on fish
minigame.interval = 2 -- time before fish changes position
minigame.movemax = 1 -- maximum distance change allowed
minigame.movetype = nil
minigame.fish = nil -- the fish youre trying to catch (reference to database)
minigame.fishlevel = nil -- actual level of fish
-- variables
minigame.pos = 0
minigame.vel = 0
minigame.progress = 0 -- 0 is loss 1 is win
minigame.timer = minigame.interval -- timer for position change
minigame.fishpos = 0
minigame.fishprev = 0
minigame.fishtarget = 0
minigame.interp = 0 -- between zero and one
minigame.gracetimer = 0

function fishingGacha()
    -- setup minigame
    minigame.timer = 0.1
    minigame.progress = minigame.start
    minigame.pos = 0.5
    minigame.vel = 0
    minigame.fishprev = minigame.pos
    minigame.fishpos = minigame.fishprev
    minigame.fishtarget = minigame.fishpos
    minigame.interp = 0
    minigame.gracetimer = minigame.gracetime

    -- setup fish values
    local fish = critterGacha() -- may need to reroll in future according to biome/level limitations
    minigame.fish = fish
    local level = love.math.random(fish.low, fish.high) -- linear for now
    minigame.fishlevel = level
        -- TODO ! add reroll here when you get there (level limitations, biome etc..)
    -- adjust difficulty
    minigame.interval = 10 / (level + 3) -- inverse with headstart
    minigame.movemax = math.sqrt(level) / 4 - 0.1 -- grows slowly
    minigame.movemin = math.sqrt(level) / 12 - 0.1 -- so that higher level fish dont stand in one spot
    -- select pattern
    if fish.pattern == "smooth" then
        minigame.movetype = interpolate.inOutSine
    elseif fish.pattern == "sharp" then
        minigame.movetype = interpolate.inOutExpo
    elseif fish.pattern == "bouncy" then
        minigame.movetype = interpolate.inOutBack
    else
        minigame.movetype = interpolate.linear -- default value
    end

    -- DEBUG
    --print(fish.name.." lv"..level)
end

-- the main minigame
function fishingMinigame(dt)
    -- end condition
    if minigame.progress <= 0 then
        return "idle" -- lost
    elseif minigame.progress >= 1 then
        return "caught" -- won
    end

    -- +y is up
    local lmb = love.mouse.isDown(1)
    if lmb then minigame.vel = minigame.vel + minigame.acc * dt
    else        minigame.vel = minigame.vel - minigame.acc * dt end

    -- bounds
    if      minigame.pos - minigame.area/2 <= 0 and minigame.vel < 0 then
        minigame.vel = -minigame.vel * minigame.bounce
    elseif  minigame.pos + minigame.area/2 >= 1 and minigame.vel > 0 then
        minigame.vel = -minigame.vel * minigame.bounce
    end

    minigame.pos = minigame.pos + minigame.vel * dt -- update bar

    -- fish
    if minigame.timer < 0 then -- choose new pos, maybe make a function for this ?
        minigame.timer = minigame.interval
        minigame.interp = 0
        minigame.fishprev = minigame.fishtarget
        repeat
            minigame.fishtarget = love.math.random()
            local dist = math.abs(minigame.fishprev - minigame.fishtarget)
        until minigame.movemin < dist and dist < minigame.movemax
    end
    minigame.timer = minigame.timer - dt
    minigame.interp = minigame.interp + dt / minigame.interval
    -- different fish can have different interpolations
    minigame.fishpos = minigame.movetype(minigame.fishprev, minigame.fishtarget, minigame.interp)
    local edges = 0.1
    minigame.fishpos = minigame.fishpos * (1 - 2 * edges) + edges

    -- progress
    if minigame.pos + minigame.area/2 >= minigame.fishpos and minigame.fishpos >= minigame.pos - minigame.area/2 then
        minigame.progress = minigame.progress + dt / minigame.twin
    else
        if minigame.gracetimer <= 0 then -- grace time
            minigame.progress = minigame.progress - dt / minigame.tlose
        end
    end
    minigame.gracetimer = minigame.gracetimer - dt

    return "reeling"
end

-- physics for hook/bobber
do
    local hookpress = function () hook.held = true end
    local hookrelease = function () hook.held = false end
    hook = {
        x = 260, y = 220,
        vx = 0, vy = 0,
        gravity = 900,
        held = false,
        button = newButton("hook", 0, 0, 48, 48, hookpress, hookrelease)
    }
end
local spring = { -- simulate hook as a point attached to this (-1's are set dynamically)
    x = -1, y = -1,
    len = -1, k = 400, friction = -1, strain = 7,
    minlen = 70, maxlen = 125
}
local oldFishingState = ""
local tipx, tipy = 0, 0
function simulateRod(dt)
    if dt > 1 then return end -- lag safeguard
    local falling = fishing.bobber == "falling" -- shorthand

    -- update button
    hook.button.x = hook.x - hook.button.width / 2
    hook.button.y = hook.y - hook.button.height / 2
    -- if being held just follow cursor
    if hook.held and (fishing.state == "idle" or fishing.state == "caught") then
        local mx, my = love.mouse.getX(), love.mouse.getY()
        mx, my = screenSpaceToGame(mx, my)
        hook.vx, hook.vy = (mx - hook.x) / dt / 2, (my - hook.y) / dt / 2 -- pick up and throw
        hook.x, hook.y = mx, my
        --hook.vx, hook.vy = 0, 0 -- no throw

        local dist = math.sqrt((hook.x - spring.x)^2 + (hook.y - spring.y)^2)
        spring.len = math.bound(dist, spring.minlen, spring.maxlen) -- optionally set length using this
        return
    end

    -- calculate force and direction
    if not falling then -- ignore spring on freefall
        local dist = math.sqrt((hook.x - spring.x)^2 + (hook.y - spring.y)^2)
        local force = spring.k * math.min(spring.strain, (dist - spring.len)) -- hooke's law (modified)
        local unit = { -- force's unit vector
            x = (spring.x - hook.x) / dist,
            y = (spring.y - hook.y) / dist,
        }
        -- apply force
        if dist > 0 and force > 0 then
            if fishing.state ~= "fishing" then -- ignore horizontal spring forces when on surface
                hook.vx = hook.vx + unit.x * force * dt end
            hook.vy = hook.vy + unit.y * force * dt
        end
    end
    -- gravity
    hook.vy = hook.vy + hook.gravity * dt
    -- apply velocity
    hook.x = hook.x + hook.vx * dt
    hook.y = hook.y + hook.vy * dt
    -- apply friction-ish
    hook.vx = hook.vx - hook.vx * spring.friction * dt / 2
    hook.vy = hook.vy - hook.vy * spring.friction * dt


    -- change positions according to state
    if fishing.state ~= oldFishingState then
        if fishing.state == "idle" or fishing.state == "caught" then
            tipx, tipy = 188, 153
            spring.x = tipx; spring.y = tipy
            spring.len = 100; spring.friction = 1.5
        elseif fishing.state == "fishing" then
            tipx, tipy = 188, 153
            spring.x = hook.x; spring.y = Height - 3
            spring.len = 0; spring.friction = 5
        elseif fishing.state == "reeling" then
            tipx, tipy = 188, 153
            spring.x = Width/2; spring.y = Height * 1.2
            spring.len = 0; spring.friction = 5
        else
            print("DEBUG invalid fishing state") --debug
        end
        oldFishingState = fishing.state
    end
    -- special rules apply when on water
    if fishing.state == "fishing" then
        -- check bounds when fishing just in case
        if hook.x > Width * 5/6 then
            hook.vx = hook.vx - dt * 400
        elseif hook.x < Width * 1/6 then
            hook.vx = hook.vx + dt * 400
        end
        -- update spring x every frame if on water
        spring.x = hook.x;
        -- also update y to surface height
        spring.y = getSurfaceHeight(hook.x) - 6; -- magic number for added float
    end

    -- check falling state
    if fishing.bobber == "falling" then
        hook.vy = hook.vy + hook.gravity * dt -- apply extra gravity for shorter fall
        if hook.y >= getSurfaceHeight(hook.x) then -- landed
            fishing.bobber = "landed" -- update bobber state
        end
    end
end

-- Graphics Below --

function drawMinigame()
    local w, h = 28, Height * 0.65
    local x, y = Width/2 - w/2, Height/2 - h/2
    local div = 1/4
    local sp = sprite.minigameIndicator
    local fairness = sp:getHeight()/2
    
    -- bg
    love.graphics.setColor(c255(unpack(ui.colorBg)))
    love.graphics.rectangle("fill", x, y + fairness, w, h - 2 * fairness, 2)
    
    -- progress color
    local p = minigame.progress; local p2 = 0.4
    local fail = {255, 77, 41}
    local inter = {255, 202, 28};
    local win = {113, 255, 94}
    if p < p2 then
        love.graphics.setColor(c255(unpack(interpolateColor(fail, inter, p/p2))))
    else
        love.graphics.setColor(c255(unpack(interpolateColor(inter, win, (p-p2)/(1-p2)))))
    end
    if p > 0 then
        love.graphics.rectangle("fill", x + w*(1-div), y + (h - 2 * fairness)*(1 - p) + fairness, w*div, (h - 2 * fairness) * p, 2) -- progress
    end
    
    -- indicator
    local pos = minigame.pos
    local area = minigame.area
    love.graphics.setColor(c255(240, 240, 240))
    love.graphics.rectangle("fill", x, y + h - (pos + area/2) * h + fairness, w*(1-div), h*area - 2 * fairness, 2)

    -- fish
    local fishx, fishy = (x + w * (1-div)/2) - sp:getWidth()/2, (y + h - minigame.fishpos * h) - sp:getHeight()/2
    love.graphics.draw(sp, fishx, fishy)

    -- border
    love.graphics.setColor(c255(unpack(ui.colorBorder)))
    love.graphics.setLineWidth(ui.lineWidth)
    love.graphics.rectangle("line", x, y + fairness, w, h - 2 * fairness, 2)
end

-- mix of animation and procedural
function drawRod()
    local sp -- short name for sprite being drawn
    love.graphics.setColor(1, 1, 1, 1) -- full color

    -- TODO animations
    sp = sprite.rod1
    love.graphics.draw(sp, 30, Height - sp:getHeight() + 5)
end

function drawBobber()
    local sp -- short name for sprite being drawn
    love.graphics.setColor(1, 1, 1, 1) -- full color

    -- line
    love.graphics.setLineWidth(1)
    love.graphics.line(tipx, tipy, hook.x, hook.y)

    -- bobber and fish
    sp = sprite.bobber
    love.graphics.draw(sp, hook.x - sp:getWidth()/2, hook.y - sp:getHeight()/2)

    local drawx = hook.x
    local drawy = hook.y + sp:getHeight()/2 + 12

    if fishing.state == "caught" then
        -- also draw fish sprite
        sp = minigame.fish.sprite
        if sp ~= nil then
            love.graphics.draw(sp, drawx - sp:getWidth()/2, drawy - sp:getHeight()/2)
        else
            love.graphics.setColor(0.8, 0.5, 1, 0.5) -- debug
            love.graphics.circle("fill", drawx, drawy, 24) -- debug
        end
    end
end
