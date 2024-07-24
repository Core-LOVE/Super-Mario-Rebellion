local extraBGOProperties = require("scripts/extraBGOProperties")

local leaves = {2, 3}

for k,v in ipairs(leaves) do
    extraBGOProperties.registerID(v, {
        movementFunc = function(v,t)
            local data = extraBGOProperties.getData(v)

            data.rotation = math.sin(t) * 4;
        end,

        pivotX = 0.5,
        pivotY = 0.5,
    })
end

local grass = {776, 777}

for k,v in ipairs(grass) do
    extraBGOProperties.registerID(v, {
        movementFunc = function(v,t)
            local data = extraBGOProperties.getData(v)

            data.rotation = math.cos(t) * 4;
        end,

        pivotX = 0.5,
        pivotY = 1,
    })
end

extraBGOProperties.registerID(4, {
    parallaxX = 0.75
})