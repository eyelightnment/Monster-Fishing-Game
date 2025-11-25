function love.conf(t)
    t.version = "11.5"
    t.window.title = "Monster Fishing"
    t.modules.joystick = false
    t.modules.physics = false
    --[[ debug
    t.window.resizable = true
    t.window.minwidth = 480
    t.window.minheight = 360
    --]]
    t.window.fullscreen = false -- change this with F11
end
