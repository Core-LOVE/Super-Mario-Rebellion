--[[

    foreShadows.lua
    by MrDoubleA

]]

local foreShadows = {}


-- The color of any "shadows".
foreShadows.shadowColor = Color(0,0,0,0.75)

-- Priority where sprites will start having a "shadow".
foreShadows.backPriority = -59
-- Priority where sprites stop having a "shadow".
foreShadows.middlePriority = -21
-- Priority where sprites will stop causing sprites to have a "shadow".
foreShadows.forePriority = -16
foreShadows.forePriority2 = nil

local backBuffer = Graphics.CaptureBuffer(800,600)
local middleBuffer = Graphics.CaptureBuffer(800,600)
local foreBuffer = Graphics.CaptureBuffer(800,600)

local mainShader = Shader()
mainShader:compileFromFile(nil,"libraries/foreShadows.frag")


function foreShadows.onCameraDraw(camIdx)
    local c = Camera(camIdx)

    backBuffer:captureAt(foreShadows.backPriority)
    middleBuffer:captureAt(foreShadows.middlePriority)
    foreBuffer:captureAt(foreShadows.forePriority)

    Graphics.drawScreen{
        priority = foreShadows.forePriority,
        color = foreShadows.shadowColor,
        
        shader = mainShader,uniforms = {
            backBuffer = backBuffer,
            middleBuffer = middleBuffer,
            foreBuffer = foreBuffer,
        },
    }
end


function foreShadows.onInitAPI()
    registerEvent(foreShadows,"onCameraDraw")
end


return foreShadows