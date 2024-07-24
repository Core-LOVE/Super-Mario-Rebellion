local extraBGOProperties = require("scripts/extraBGOProperties")

local grass = {982, 983}

for k,v in ipairs(grass) do
    extraBGOProperties.registerID(v, {
        movementFunc = function(v,t)
            local data = extraBGOProperties.getData(v)

            data.rotation = math.cos(t) * 2;
        end,

        pivotY = 0,
        pivotY = 1,
    })
end

extraBGOProperties.registerID(2, {
    movementFunc = function(v,t)
        local data = extraBGOProperties.getData(v)

        data.rotation = t * 24;
    end,
})