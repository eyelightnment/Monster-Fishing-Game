function c255(r, g, b, a) -- convert 0-255 to 0-1
    a = a or 255
    return r/255, g/255, b/255, a/255
end

function interpolateColor(colorA, colorB, p)
    local color = {}
    for i = 1,3 do color[i] = ((colorB[i] - colorA[i]) * p + colorA[i]) end
    return color
end

local surface = {} -- will store the last wave data for physics simulation to use

function getSurfaceHeight(x)
    local xvalues = {}
    for x, _ in pairs(surface) do table.insert(xvalues, x) end
    table.sort(xvalues) -- sort xvalues
    local len = #xvalues

    -- first check edge cases
    if x <= xvalues[1] then
        return surface[xvalues[1]]
    elseif x >= xvalues[len] then
        return surface[xvalues[len]]
    else
        for i = 2, len do -- check between bounds
            local left, right = xvalues[i-1], xvalues[i]
            if left <= x and x <= right then -- found interval
                local alpha = (x - left) / (right - left) -- interpolation value
                return alpha * (surface[left]) + (1 - alpha) * (surface[right]) -- linear guess
            end
        end
    end
end

local function drawWaves(waveFunction, iterations, power, horizonHeight, bottomHeight, time, colorA, colorB)
    surface = {} -- reset surface data
    if iterations < 1 then return end -- safeguard

    local xStep = 5 -- pixels
    local xOffset = Width * 10 -- so that all waves dont converge on the left side
    --local xOffset = -Width/2 -- do this if you want waves to converge on center

    local index = 1
    while index <= iterations do -- move in y axis
        local scale = ((index / iterations) ^ power)
        local y = horizonHeight + (bottomHeight - horizonHeight) * scale

        local x = 0
        local line = {}
        while x <= Width do -- move in x axis
            local yOffset = waveFunction((x + xOffset) / scale, time) -- calculate offset from wave function
            table.insert(line, x) -- add x to line
            table.insert(line, y + yOffset * scale) -- add y to line
            if index == iterations then -- last loop
                surface[x] = y + yOffset * scale -- add to surface data
            end
            x = x + xStep
        end
        -- add bottom to line
        table.insert(line, Width)
        table.insert(line, Height * 1.5) -- bottom right
        table.insert(line, 0)
        table.insert(line, Height * 1.5) -- bottom left
        
        -- make this part modular
        local p = (index-1) / (iterations-1) -- goes from 0 to 1
        if iterations <= 2 then p = 1 end -- safeguard when iterations is 1
        local color = interpolateColor(colorA, colorB, p)
        love.graphics.setColor(c255(unpack(color))) -- color

        --draw polygons here
        local triangles = love.math.triangulate(unpack(line)) -- turn into triangles for concavity
        for i, tri in ipairs(triangles) do
            love.graphics.polygon("fill", unpack(tri)) -- unpack values and send to love
        end

        index = index + 1
    end
end

local waveFunc = {}

function waveFunc.line(x, time)
    return 0
end

function waveFunc.sineStatic(x, time)
    local arcWidth, arcHeight = 100, 15
    return math.sin(x / arcWidth) * arcHeight
end

function waveFunc.sine(x, time)
    local arcWidth, arcHeight, speed = 100, 20, 80
    return math.sin((x + time * speed) / arcWidth) * arcHeight
end

function waveFunc.sineMulti(x, time) -- add multiple sine waves for "sealike" look
    local sum = 0
    ---[[ stylised
    x = x * 1.2
    sum = sum + waveFunc.sine(x, time * 1.1) * 0.60
    sum = sum + waveFunc.sine(x/2, time * -2) * 0.30
    sum = sum + waveFunc.sine(x*2, time / -2) * 0.10
    -- details
    --sum = sum + waveFunc.sine(x*4, time * 1.1) * 0.06
    --sum = sum + waveFunc.sine(x/2*4, time * -2) * 0.03
    --sum = sum + waveFunc.sine(x*2*4, time / -2) * 0.01
    --]]
    --[[ chat-gpt suggestion that looks more realistic
    x = x * 6
    time = time * 1.5
    sum = 
    waveFunc.sine(x * 0.08, time * 0.708) * 1.0 +
    waveFunc.sine(x * 0.21, time * -1.12) * 0.6 +
    waveFunc.sine(x * 0.41, time * 1.58) * 0.25 +
    waveFunc.sine(x * 0.81, time * 2.24) * 0.10 +
    waveFunc.sine(x * 1.51, time * 3.07) * 0.04
    --]]

    return sum
end

local function drawSky(colorA, colorB, horizonHeight)
    local yStep = 1
    local y = horizonHeight
    while y >= 0 do
        local p = (1 - (y / horizonHeight))
        love.graphics.setColor(c255(unpack(interpolateColor(colorA, colorB, p))))
        love.graphics.rectangle("fill", 0, y, Width, yStep)
        y = y - yStep
    end
end

local clouds = {} -- store objects
cloud = {} -- store properties
cloud.targetnum = 4000 -- maybe change dynamically with weather
cloud.actualnum = 0 -- keep count
cloud.lifetime = 20
cloud.size = 5
cloud.wind = -2.5 -- in x axis for now
cloud.cluster = 20 -- spawn in clusters of n

function simulateClouds(dt, horizon)
    for k, v in pairs(clouds) do
        -- simulate clouds & delete
        v.remlife = v.remlife - dt
        v.x = v.x + v.wind * dt

        if v.remlife < 0 then -- delete old ones
            clouds[k] = nil
            cloud.actualnum = cloud.actualnum - 1 -- decrement count
        end
    end

    while cloud.actualnum < cloud.targetnum do
        -- make cluster
        local x = Width * (-0.2 + love.math.random() * 1.4)
        local y = horizon * (1 - love.math.random() ^ 3) -- more clouds at bottom
        local color = love.math.random()
        local wind = cloud.wind * (0.5 + love.math.random())
        for i = 1, cloud.cluster do
            -- make new cloud
            local key = love.math.random(1, 10000) -- arbitrary large random id
            while clouds[key] ~= nil do key = love.math.random(1, 10000) end -- retry if same id

            local life = cloud.lifetime * (0.8 + love.math.random() * 0.4) -- add divergence to avoid clumping
            local newcloud = {
                maxlife = life,
                remlife = life, -- keeping another variable to dynamically draw size based on max life
                x = x + love.math.randomNormal(10, 0),
                y = y + love.math.randomNormal(5, 0),
                color = color,
                wind = wind
            }

            clouds[key] = newcloud -- add to pool
            cloud.actualnum = cloud.actualnum + 1 -- increment count
        end
    end
end

local function drawClouds(colorA, colorB)
    local sortedkeys = {}
    for k, _ in pairs(clouds) do
        table.insert(sortedkeys, k)
    end
    table.sort(sortedkeys)

    for _, key in ipairs(sortedkeys) do
        local v = clouds[key]
        local p = (v.maxlife - v.remlife) / v.maxlife -- goes from 1 to 0 linearly
        local size = cloud.size * math.sin(p * 3.14) -- smooth curve
        if size > 0 then
            love.graphics.setColor(c255(unpack(interpolateColor(colorA, colorB, v.color))))
            love.graphics.circle("fill", v.x, v.y, size)
        end
    end
end

drawScene = {
    Ocean = function (surfaceOnly)
        -- colors
        local skyUp, skyDown = {84, 53, 102}, {186, 102, 109} -- more vibrant version
        --local skyUp, skyDown = {91, 68, 105}, {173, 109, 115} -- desaturated
        local cloud1, cloud2 = {238, 242, 221}, {216, 175, 154}
        local seaUp, seaDown = {134, 155, 217}, {0, 12, 36}
        --[[ monochrome blue
            local skyUp = {194, 239, 235}
            local skyDown = {65, 51, 122}
            local cloud1, cloud2 = {194, 239, 235}, {236, 254, 232}
            local seaUp = {110, 164, 191}
            local seaDown = {51, 30, 54}
        --]]
        --[[ sunset
            local skyUp = {120, 69, 177}
            local skyDown = {255, 94, 133}
            local cloud1, cloud2 = {255, 94, 133}, {255, 164, 86}
            local seaUp = {255, 94, 133}
            local seaDown = {4, 20, 56}
        --]]
        --[[ cotton candy
            local cHorizon = {238, 114, 142}
            local cSea = {77, 9, 110}
            local cCloud = {245, 185, 169}
            local cSky = {153, 31, 101}
            local skyUp, skyDown = cSky, cHorizon
            local cloud1, cloud2 = cHorizon, cCloud
            local seaUp, seaDown = cHorizon, cSea
        --]]

        if surfaceOnly then
            drawWaves(waveFunc.sineMulti, 1, 2, Horizon, Height * 0.91, TotalTime, seaUp, seaDown)
            return
        end
        drawSky(skyDown, skyUp, Horizon + 10)
        drawClouds(cloud1, cloud2)
        drawWaves(waveFunc.sineMulti, 18, 2, Horizon, Height * 0.9, TotalTime, seaUp, seaDown)
    end
}
