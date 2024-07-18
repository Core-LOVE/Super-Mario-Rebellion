local hud = require("scripts/hud")
local data = require("scripts/data")
local playerphysicspatch = require("scripts/playerphysicspatch")
local jumpBuffer = require("scripts/jumpBuffer")
local coyotetime = require("scripts/coyotetime")
local cp = require("scripts/customPowerups")
local extraBGOProperties = require("scripts/extraBGOProperties")
local extendedKoopas = require("scripts/npc/extendedKoopas")
local transition = require("transition")

cp.addPowerup("Cape", "scripts/powerups/cape", 851, true)

require("scripts/enchanced_camera")
require("scripts/retroResolution")
require("scripts/warpTransition")
require("scripts/inertia")
require("scripts/quickPipes")
require("scripts/fallParticles")
require("scripts/fastfall")

local SCREEN_SIZE = data.screen

function onStart()
    Player.setCostume(CHARACTER_MARIO,"SMW-Mario",true)
    Graphics.setMainFramebufferSize(SCREEN_SIZE[1], SCREEN_SIZE[2])
end

function onCameraUpdate()
    camera.width,camera.height = Graphics.getMainFramebufferSize()
end

local saveGateData = {
    speedY = 0,
    enabled = false,
    forceZero = false,
}

local function saveGate(layer)
    saveGateData.enabled = true
    saveGateData.speedY = -6

    transition.to(saveGateData, 64, transition.EASING_INOUTSINE, {speedY = 6})

    Routine.waitFrames(63)

    saveGateData.forceZero = true

    Routine.waitFrames(1)

    saveGateData.enabled = false
end

function onCheckpoint(checkpoint, p)
    Routine.run(saveGate)

    local e = Effect.spawn(998, p.x, p.y)
    e.speedX = p.speedX * 1.5
    e.speedY = -(math.abs(p.speedY) + 8)

    for i = 0, 8 do
        local e = Effect.spawn(261, p)
        e.speedX = math.random(-2, 2)
        e.speedY = -math.random(4, 6)
    end
end

function onTickEnd()
    if (not saveGateData.enabled) then return end

    local layer = Layer.get("Save Gate")

    if saveGateData.forceZero then layer.speedY = 0 return end
    layer.speedY = saveGateData.speedY
end