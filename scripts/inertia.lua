--[[
	inertia.lua v1.0 by "Master" of Disaster
	
	don't lose all your momentum when jumping off of npcs!
	
	If you credit me when using this library, you are a certified cool person
]]

local inertia = {
	keepSpeed = 1,
	maxJumpSpeed = -16,
	minJumpSpeed = -3,
	maxSpeedX = 6,
}

-- Defines.jumpspeed
local floorSpeedX = nil
local floorSpeedY = nil
local defaultJumpSpeed = -5.7
local currentJumpSpeed = -5.7
local defaultMaxSpeed = 6
local currentMaxSpeed = 6
local changedJumpspeed = true	-- true if you jumped off a platform that moves upwards
local changedRunSpeed = true
local retainedSpeed = false		-- true if you jumped off a horizontally moving platform. Resets if you touch ground or are slow enough.

registerEvent(inertia,"onTick")

local function isOnGroundRedigit() -- grounded player check. surprisingly, doing it the redigit way is more reliable than player:is On Ground()
    return (
        player.speedY == 0
        or player:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC (this is -1 when standing on a moving block. thanks redigit.)
        or player:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
    )
end

function inertia.onTick()
	
	if player.standingNPC then
		if retainedSpeed then		-- the point of this is that you don't slide off the moving platform when jumping off it and landing on it again
			player.speedX = player.speedX - player.standingNPC.speedX
			retainedSpeed = false
		end
		--Text.print(player.standingNPC.speedX,0,0)
		floorSpeedX = player.standingNPC.speedX
		floorSpeedY = player.standingNPC.speedY
	else
		if floorSpeedX and floorSpeedY then
			local newSpeedX = math.max(-inertia.maxSpeedX,math.min(inertia.maxSpeedX,player.speedX + floorSpeedX * inertia.keepSpeed))
			player.speedX = newSpeedX
			player.speedY = player.speedY + floorSpeedY	* inertia.keepSpeed
			retainedSpeed = true
			if player:mem(0x11C,FIELD_WORD) > 0 then
				Defines.jumpspeed = math.min(inertia.minJumpSpeed, math.max(inertia.maxJumpSpeed, defaultJumpSpeed + floorSpeedY * inertia.keepSpeed))
				changedJumpspeed = true
			end
			if newSpeedX >= defaultMaxSpeed then
				changedRunSpeed = true
				currentMaxSpeed = newSpeedX
			end
			floorSpeedX = nil
			floorSpeedY = nil
		end
	end
	
	if player:mem(0x11C,FIELD_WORD) == 0 and changedJumpspeed then
		Defines.jumpspeed = defaultJumpSpeed
		changedJumpspeed = false
	end
	
	if changedRunSpeed then
		if math.abs(player.speedX) <= defaultMaxSpeed or isOnGroundRedigit() then
			currentMaxSpeed = defaultMaxSpeed
			changedRunSpeed = false
			Defines.player_runspeed = currentMaxSpeed
			Defines.player_walkspeed = currentMaxSpeed * 0.5
		else
			currentMaxSpeed = player.speedX
		end
		Defines.player_runspeed = currentMaxSpeed
		Defines.player_walkspeed = currentMaxSpeed * 0.5
	end
	
	if player:isOnGround() or math.abs(player.speedX) < 1 then
		retainedSpeed = false
	end
end

return inertia