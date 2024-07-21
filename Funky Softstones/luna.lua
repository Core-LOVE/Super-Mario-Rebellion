local extraBGOProperties = require("scripts/extraBGOProperties")
local transition = require("transition")

local grass = {3, 7, 6}
local umbrella = {863, 864, 865, 866}

for k,v in ipairs(grass) do
    extraBGOProperties.registerID(v, {
        movementFunc = function(v,t)
            local data = extraBGOProperties.getData(v)

            data.scaleX = 1 + math.abs(math.sin(t + t) * .32)
        end,
    })
end

for k,v in ipairs(umbrella) do
    extraBGOProperties.registerID(v, {
        movementFunc = function(v,t)
            local data = extraBGOProperties.getData(v)

            data.rotation = math.cos(t);
        end,

        pivotY = 1,
    })
end

local shader = Shader()
shader:compileFromFile(nil, "scripts/shaders/effects/cooler_wave.frag")

local myBuffer = Graphics.CaptureBuffer()

local drawArgs = {
    shader = shader,
    texture = myBuffer,
    uniforms = {
        time = lunatime.tick(),
        time2 = lunatime.tick() * .01, 
        intensity = 0.5,
        intensity2 = 0.032,
        type = 0,
    },

    priority = 0
}

local ending = 0.24
local start = 0.15

function onDraw()
    myBuffer:clear(start)
    Graphics.redirectCameraFB(myBuffer, start, ending)

    drawArgs.texture = myBuffer
    drawArgs.uniforms.time = lunatime.tick()
    drawArgs.uniforms.time2 = lunatime.tick() * .01

    Graphics.drawScreen(drawArgs)
end

local function move()
    local delay = 96
    local speed = 1.5
    local layer1 = Layer.get("moving1")
    local layer2 = Layer.get("moving2")

    transition.to(layer1, delay, transition.EASING_INOUTSINE, {speedY = speed})
    transition.to(layer2, delay, transition.EASING_INOUTSINE, {speedY = -speed})

    Routine.waitFrames(delay)

    transition.to(layer1, delay, transition.EASING_INOUTSINE, {speedY = -speed})
    transition.to(layer2, delay, transition.EASING_INOUTSINE, {speedY = speed})

    Routine.waitFrames(delay)

    Routine.run(move)
end

function onStart()
    Routine.run(move)
end