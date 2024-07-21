local extraBGOProperties = require("scripts/extraBGOProperties")
local clearpipe = require("blocks/ai/clearpipe")
clearpipe.registerNPC(36)

local waterY = -199552
local waterY2 = -120608
local waterIsDown = nil

local waterfall = {833, 832, 821}

for k,v in ipairs(waterfall) do
    extraBGOProperties.registerID(v,{
        getUniformsFunc = function(id,camIdx)
            local cam = Camera(camIdx)

            if cam.y >= -180600 then 
                return {
                    waterY = waterY2 - cam.y, 
                } 
            end

            return {
                waterY = waterY - cam.y,
            }
        end,

        fragShader = "waterfall.frag",
    })
end

local function downWater()
    local timer = 700
    local layer = Layer.get("water")
    local speed = 1

    waterIsDown = speed
    layer.speedY = speed

    Routine.waitFrames(timer)

    waterIsDown = nil
    layer.speedY = 0
end

local waterLayer

function onStart()
    waterLayer = Section(0).background:get("water")
end

function onEvent(name)
    if (name == "switch") then
        SFX.play("water_drain.ogg", 0.5)
        Routine.run(downWater)
    end
end

function onTick()
    if not waterIsDown then return end

    waterY = waterY + waterIsDown
    waterLayer.y = waterLayer.y + waterIsDown
end