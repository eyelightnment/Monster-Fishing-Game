--[[
each creature should have:
level range - its power and difficulty to catch
rarity - rarer fish appear less
pattern - pattern used for fishing minigame (smooth bouncy sharp)
biomes - fishing locations at which they are available (ocean snow sand mud lava sky void)
sprite - artwork
flavortext - description
--]]

critters = {
    {
        name = "Sunfish",
        flavortext = "Can survive a bite or two.",
        sprite = sprite.cSunfish,
        low = 2, high = 4,

        rarity = 1,
        pattern = "smooth",
        biomes = nil,
        elements = nil,
    },
    {
        name = "Slime",
        flavortext = "May adapt to its biome.",
        sprite = sprite.cSlime,
        low = 1, high = 3,

        rarity = 1,
        pattern = "bouncy",
        biomes = nil,
        elements = nil,
    },
    {
        name = "Black Dragon",
        flavortext = "Spits acid at its prey.",
        sprite = sprite.cBlackDragon,
        low = 5, high = 8,

        rarity = 1.5,
        pattern = "sharp",
        biomes = nil,
        elements = nil,
    },
    {
        name = "Blue Dragon",
        flavortext = "Calls lightning upon its prey.",
        sprite = sprite.cBlueDragon,
        low = 7, high = 10,

        rarity = 1.5,
        pattern = "smooth",
        biomes = nil,
        elements = nil,
    },
    {
        name = "Undine",
        flavortext = "Water spirit, in part slime.",
        sprite = sprite.cUndine,
        low = 11, high = 13,

        rarity = 3,
        pattern = "bouncy",
        biomes = nil,
        elements = nil,
    },
}

function critterGacha()
    local weight = function (x) return 1/(2^x) end
        
    local total = 0
    for _, v in ipairs(critters) do -- sum up weights
        total = total + weight(v.rarity)
    end

    local draw = love.math.random() * total -- real num between 0 and total weight
    local critter
    for _, v in ipairs(critters) do -- check which one the draw landed on
        draw = draw - weight(v.rarity)
        if draw < 0 then critter = v break end -- we found it
    end

    return critter
end
