local hud = require("scripts/hud")
local data = require("scripts/data")
local playerphysicspatch = require("scripts/playerphysicspatch")
local jumpBuffer = require("scripts/jumpBuffer")
local coyotetime = require("scripts/coyotetime")
local cp = require("scripts/customPowerups")
local extraBGOProperties = require("scripts/extraBGOProperties")
local extraNPCProperties = require("scripts/extraNPCProperties")
local extendedKoopas = require("scripts/npc/extendedKoopas")
local transition = require("transition")

cp.addPowerup("Cape", "scripts/powerups/cape", 851, true)

require("scripts/enchanced_camera")
require("scripts/retroResolution")
require("scripts/warpTransition")
-- require("scripts/inertia")
require("scripts/quickPipes")
require("scripts/fallParticles")
require("scripts/fastfall")
require("scripts/jumpinwater")
require("scripts/littleDialogue")
require("scripts/death")
require("scripts/altjumpInAir")
require("scripts/anotherPowerDownLibrary")
require("scripts/collectEffect")
require("scripts/fastFireBalls")
require("scripts/newEffects")
require("scripts/betterReserve")

local SCREEN_SIZE = data.screen

Misc.setWindowTitle(data.window_title)
Misc.setWindowIcon(Graphics.loadImageResolved("graphics/icon.png"))

function onStart()
    Player.setCostume(CHARACTER_MARIO,"smw",true)
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

local effectTimer = {
    [1] = 0
}

local function effects()
    effectTimer[1] = effectTimer[1] + 1

    if effectTimer[1] >= 4 then
        for k,v in ipairs(Effect.get(1)) do
            local e = Effect.spawn(999, v.x, v.y)
            e.opacity = 0.5
        end

        effectTimer[1] = 0
    end

    for k,v in ipairs(Effect.get(11)) do
        Effect.spawn(997, v.x + 16, v.y + 16)
        v.timer = 0
        v.animationFrame = -1000
    end
end

function onTickEnd()
    effects()

    if (not saveGateData.enabled) then return end

    local layer = Layer.get("Save Gate")

    if saveGateData.forceZero then layer.speedY = 0 return end
    layer.speedY = saveGateData.speedY
end

function onPostBlockRemove(block)
    local w = (block.width - 32) * .5
    local h = (block.height - 32) * .5

    Effect.spawn(131, block.x + h, block.y + w)
end

function onPlayerHarm(e, p)
    Defines.earthquake = 8
end

-- function onPostNPCHarm(v, harmType, c)
--     local e = Effect.spawn(994, v)
--     e.variant = math.random(1, 2)
-- end

-- function onPostBlockHit(v)
--     if not c then return end
     
--     local e = Effect.spawn(994, v)
--     e.variant = math.random(1, 2)
--     e.opacity = 0.38
-- end