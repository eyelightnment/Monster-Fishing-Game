buttons = {}
function newButton(name, x, y, width, height, action, release, z) -- topleft anchoring
    action = action or function () end -- default is do nothing
    release = release or function () end -- default is do nothing
    z = z or 0 -- lower values are on top
    buttons[name] = {
        x=x, y=y, z=z,
        width=width, height=height,
        action=action, release=release
    }
    return buttons[name]
end

function screenSpaceToGame(x, y)
    return x / Scale - Offset, y / Scale
end

function isPressed(x, y, button) -- this transforms the buttom from game space to screen space idk why
    x, y = screenSpaceToGame(x, y)
    local left = button.x
    local right = button.x+button.width
    local top = button.y
    local bottom = button.y+button.height
    if x >= left and y >= top and x < right and y < bottom then
        return true
    else
        return false
    end
end

notifs = {}
local notifID = 1
function newTextObject(text)
    local tfont = font.regular
    local t = {}
    t.height = 16
    t.width = (t.height - font.height) + ((#text + 1) * font.width) -- dynamic size
    t.text = love.graphics.newText(tfont, text)
    return t
end
function notify(text)
    local t = newTextObject(text)
    t.id = notifID
    local act = function ()
        notifs[t.id] = nil
        buttons["notif"..t.id] = nil
    end

    t.button = newButton("notif"..notifID, 0, 0, t.width, t.height, act)

    notifs[notifID] = t
    notifID = notifID + 1
end

function drawNotifications() -- TODO: Add max notif limit, draw top to bottom
    local gapHeight = 6
    local gapMargin = 12
    local top, bottom = 0, Height * 0.4
    local y = top + gapMargin
    local count = 0 -- keep track of how many boxes i drew
    --local y = Height + gapHeight - gapMargin

    local keys = {} -- get keys
    for key, _ in pairs(notifs) do table.insert(keys, key) end
    table.sort(keys, function (a, b) return a > b end) -- sort keys

    for _, key in ipairs(keys) do -- look at notifications in sorted order
        local lastLoop = (y > bottom)
        local v = nil -- notification to be drawn
    
        if lastLoop then -- exception for last loop message
            local text = (#keys - count).." more.." -- use size of "keys" because it is continuous
            v = newTextObject(text)
        else
            v = notifs[key] -- get value
        end
        
        local x = Width - gapMargin - v.width

        if not lastLoop then v.button.x = x; v.button.y = y end -- update button

        love.graphics.setColor(c255(unpack(ui.colorBg)))
        love.graphics.rectangle("fill", x, y, v.width, v.height, 2) -- rounded box

        love.graphics.setColor(c255(unpack(ui.colorBorder)))
        love.graphics.setLineWidth(ui.lineWidth)
        love.graphics.rectangle("line", x, y, v.width, v.height, 2) -- border

        local margin = (v.height - font.height) / 2
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(v.text, x + margin*2, y + margin) -- text

        if y > bottom then break end -- stop if i drew enough

        y = y + gapHeight + v.height -- update y
        count = count + 1 -- i drew a box
    end
end
