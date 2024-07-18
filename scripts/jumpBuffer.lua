--[[

    jumpBuffer.lua
    by MrDoubleA

    Allows you to press the jump button a few frames before landing and still jump.

]]

local jumpBuffer = {}

local anotherwalljump
local groundPound


jumpBuffer.enabled = true

jumpBuffer.frames = 5


local JUMPTYPE_NONE = 0
local JUMPTYPE_NORMAL = 1
local JUMPTYPE_SPIN = 2

local playerData = {}


function jumpBuffer.getPlayerData(p)
    local data = playerData[p.idx]

    if data == nil then
        data = {}
        playerData[p.idx] = data

        data.bufferedJumpType = JUMPTYPE_NONE
        data.bufferedJumpTime = 0
    end

    return data
end


local function isOnGround(p)
    return (
        p.speedY == 0 -- "on a block"
        or p:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC/moving block
        or p:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
    )
end

local function isGroundPounding(p)
    if groundPound == nil then
        return false
    end

    local gpData = groundPound.getData(p.idx)

    if gpData == nil then
        return false
    end

    return (gpData.state ~= groundPound.STATE_NONE)
end

local function cannotUseBuffer(p)
    return (
        not jumpBuffer.enabled

        or p.deathTimer > 0
        or p:mem(0x13C,FIELD_BOOL) -- player dead

        or p:mem(0x00,FIELD_BOOL) -- toad double jump
        or p:mem(0x0C,FIELD_BOOL) -- fairy
        or p:mem(0x5C,FIELD_BOOL) -- yoshi ground pound

        or (p:mem(0x34,FIELD_WORD) > 0 and p:mem(0x06,FIELD_WORD) == 0) -- in water

        or (anotherwalljump ~= nil and anotherwalljump.isWallSliding(p) ~= 0) -- wall sliding
        or isGroundPounding(p)
    )
end

local function cannotJump(p)
    return (
        not isOnGround(p)

        or p.forcedState ~= FORCEDSTATE_NONE
        or p.climbing

        or p:mem(0x4A,FIELD_BOOL) -- statue
    )
end


local function updatePlayer(p)
    local data = jumpBuffer.getPlayerData(p)

    if cannotUseBuffer(p) then
        data.bufferedJumpType = JUMPTYPE_NONE
        data.bufferedJumpTime = JUMPTYPE_NONE
        return
    end

    if cannotJump(p) then
        if p.keys.jump == KEYS_PRESSED then
            data.bufferedJumpType = JUMPTYPE_NORMAL
            data.bufferedJumpTime = jumpBuffer.frames
        elseif p.keys.altJump == KEYS_PRESSED then
            data.bufferedJumpType = JUMPTYPE_SPIN
            data.bufferedJumpTime = jumpBuffer.frames
        else
            data.bufferedJumpTime = math.max(0,data.bufferedJumpTime - 1)
        end
    else
        if data.bufferedJumpType == JUMPTYPE_NONE or data.bufferedJumpTime == 0 then
            return
        end

        if data.bufferedJumpType == JUMPTYPE_NORMAL then
            p:mem(0x11E,FIELD_BOOL,true) -- set "can jump" flag to make it work even when holding the button
            p.keys._last.jump = false -- very hacky, but should make for better compatibility with other scripts
            p.keys.jump = true

            p:mem(0x50,FIELD_BOOL,false) -- disable spin jumping
        elseif data.bufferedJumpType == JUMPTYPE_SPIN then
            p:mem(0x120,FIELD_BOOL,true)
            p.keys._last.altJump = false
            p.keys.altJump = true
        end

        data.bufferedJumpType = JUMPTYPE_NONE
        data.bufferedJumpTime = 0
    end
end


function jumpBuffer.onTick()
    for _,p in ipairs(Player.get()) do
        updatePlayer(p)
    end
end

function jumpBuffer.onInitAPI()
    pcall(function() anotherwalljump = require("scripts/anotherwalljump") end)
    pcall(function() groundPound = require("scripts/GroundPound") end)

    registerEvent(jumpBuffer,"onTick")
end


return jumpBuffer