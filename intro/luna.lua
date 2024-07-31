local transition = require("transition")
local easing = require("ext/easing")
local littleDialogue = require("scripts/littleDialogue")
local cutscenePal = require("cutscenePal")
Graphics.activateHud(false)

local imgs = {}

local function draw(name, fade)
    local texture = Graphics.loadImageResolved("intro_" .. tostring(name) .. ".png")

    local img = {
        texture = texture,
        alpha = 0,
    }

    transition.to(img, fade or 96, easing.linear, {alpha = 1})
    table.insert(imgs, img)
    return img
end

function onDraw()
    Graphics.drawScreen{
        color = Color.black,
        priority = 1,
    }

    for k,v in ipairs(imgs) do
        Graphics.drawImage(v.texture, 0, 0, v.alpha)
    end
end

function onStart()
    Routine.run(function()
        local img = draw("katebulka")

        Routine.waitFrames(400)

        transition.to(img, 96, easing.linear, {alpha = 0})

        Routine.waitFrames(200)

        local img = draw(1)

        Routine.waitFrames(96)

        littleDialogue.create{
            text = "<boxStyle dr>The Flower Kingdom and the Mushroom Kingdom are allies nowadays. However, this wasn't always the case...",      
        }

        local img = draw(2)

        Routine.waitFrames(96)

        littleDialogue.create{
            text = "<boxStyle dr>The Pollen Empire was run by a Prince Pollen, or as people call him - Rebellion.",      
        }   
    end)
end