local extraBGOProperties = require("scripts/extraBGOProperties")
local clearpipe = require("blocks/ai/clearpipe")
clearpipe.registerNPC(36)

local waterY = -199552
local waterY2 = -120608

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