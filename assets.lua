love.graphics.setDefaultFilter("nearest") -- filter

bgm = {}

bgm.sea = love.audio.newSource("sound/sea.mp3", "stream")
bgm.sea:setLooping(true)
bgm.sea:setVolume(0.10)

sfx = {}
sfx.cast = love.audio.newSource("sound/cast.mp3", "static")
sfx.cast:setVolume(0.7)
sfx.biting = love.audio.newSource("sound/biting.mp3", "static")
sfx.recall = love.audio.newSource("sound/recall.mp3", "static")
sfx.hit = love.audio.newSource("sound/hit.mp3", "static")
sfx.hit:setVolume(0.8)
sfx.reeling = love.audio.newSource("sound/reeling.mp3", "static")
sfx.reeling:setLooping(true); sfx.reeling:setVolume(0.5)

font = {}
font.regular = love.graphics.newFont("font/scientifica.ttf", 11)
font.bold = love.graphics.newFont("font/scientificaBold.ttf", 11)
font.italic = love.graphics.newFont("font/scientificaItalic.ttf", 11)

font.width = 5
font.height = 11

ui = {}
ui.colorBg = {117, 98, 87}
ui.colorBorder = {194, 151, 126}
ui.lineWidth = 1.5

sprite = {}
sprite.minigameIndicator = love.graphics.newImage("sprites/indicator.png")
sprite.bobber = love.graphics.newImage("sprites/bobber.png")
sprite.rod1 = love.graphics.newImage("sprites/rod1.png")
sprite.placeholder = love.graphics.newImage("sprites/placeholderfish.png")
-- critters
sprite.cSlime = love.graphics.newImage("sprites/slime.png")
sprite.cSunfish = love.graphics.newImage("sprites/sunfish.png")
sprite.cBlackDragon = love.graphics.newImage("sprites/blackdragon.png")
sprite.cBlueDragon = love.graphics.newImage("sprites/bluedragon.png")
sprite.cUndine = love.graphics.newImage("sprites/undine.png")


-- some math functions
interpolate = {}
function interpolate.linear(a, b, p)
    return a + (b - a) * p end
function interpolate.inOutSine(a, b, p)
    return a + (b - a) * -(math.cos(3.14 * p) - 1) / 2 end
function interpolate.inOutExpo(a, b, p)
    local x
    if     p == 0  then x = 0
    elseif p == 1  then x = 1
    elseif p < 0.5 then x = (2 ^ (20 * p - 10)) / 2
    else                x = (2 - (2 ^ (-20 * p + 10))) / 2
    end
    return a + (b - a) * x end
function interpolate.inOutElastic(a, b, p) -- very steep
    local c = (2 * 3.14) / 4.5
    local x
    if     p == 0  then x = 0
    elseif p == 1  then x = 1
    elseif p < 0.5 then x = -((2 ^ (20 * p - 10)) * math.sin((20 * p - 11.125) * c)) / 2
    else                x = ((2 ^ (-20 * p + 10)) * math.sin((20 * p - 11.125) * c)) / 2 + 1
    end
    return a + (b - a) * x end
function interpolate.inOutBack(a, b, p)
    local c1 = 1.70158
    local c2 = c1 * 1.525
    local x
    if p < 0.5 then x = (((2 * p) ^ 2) * ((c2 + 1) * 2 * p - c2)) / 2
    else            x = (((2 * p - 2) ^ 2) * ((c2 + 1) * (p * 2 - 2) + c2) + 2) / 2;
    end
    return a + (b - a) * x end

function math.bound(x, min, max)
    return math.min(math.max(min, x), max)
end
