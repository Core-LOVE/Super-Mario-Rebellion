local extraBGOProperties = require("scripts/extraBGOProperties")
-- local foreShadows = require("libraries/foreShadows")
-- foreShadows.forePriority = -9.9975
-- foreShadows.shadowColor = Color.fromHex(0x3F1500BF)

local effect = Particles.Emitter(0, 0, "p_fallingleaf.ini")
effect:AttachToCamera(camera)

function onCameraDraw()
    effect:Draw()
end

extraBGOProperties.registerID(1,{
    movementFunc = function(v,t)
        local data = extraBGOProperties.getData(v)

        data.scaleY = 1 + math.sin(t) * 0.01
        data.scaleX = 1 + math.cos(t) * 0.025
		
		data.rotation = math.sin(t) * 1.75
    end,
	
	pivotY = 1,
})

extraBGOProperties.registerID(2,{
    movementFunc = function(v,t)
        local data = extraBGOProperties.getData(v)

        data.scaleY = 1 + math.sin(t) * 0.01
        data.scaleX = 1 + math.cos(t) * 0.025
		
		data.rotation = math.sin(t) * 1.75
    end,
	
	pivotY = 1,
})