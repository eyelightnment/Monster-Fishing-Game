local drops = {}
local size = 1.5 -- size of particles
local gravity = 1000 -- pixels/s^2

splash = {} -- stores simulate draw and create functions

function splash.new(x, y, count, height, spread) -- form new splash vfx
    for _ = 1, count do
        local id
        repeat id = love.math.random(1, 10000) until drops[id] == nil -- assign random id

        local speed = (2 * height * gravity) ^ 0.5 -- physics stuff y'know
        local vx, vy = love.math.randomNormal() * spread, love.math.randomNormal() * spread * 2.5

        drops[id] = {
            x = x, y = y,
            vx = vx, vy = vy - speed, -- multiply by gravity to keep height constant
            shine = love.math.random() -- color randomization
        }
    end
end

function splash.simulate(dt) -- basic physics
    for key, drop in pairs(drops) do
        -- velocity
        drop.x = drop.x + drop.vx * dt
        drop.y = drop.y + drop.vy * dt
        -- gravity
        drop.vy = drop.vy + gravity * dt

        if drop.y > Height * 1.5 then -- deletion if offscreen
            drops[key] = nil
        end
    end
end

function splash.draw()
    local white = {255, 255, 255}
    local color = {128, 131, 237}

    for _, drop in pairs(drops) do
        local c = interpolateColor(color, white, drop.shine)
        love.graphics.setColor(c255(unpack(c)))

        local time = 0.002
        local offx, offy = drop.vx * time, drop.vy * time
        local iter = 16
        for i = -iter/2, iter/2 do
            love.graphics.circle("fill", drop.x - offx * i, drop.y - offy * i, size * (iter - math.abs(i))/iter)
        end
    end
end
