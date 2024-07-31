local ai = {}

local transition = require("transition")
local blockManager = require("blockManager")

ai.idMap = {}
ai.rotationSettings = {
	easing = transition.EASING_INOUTSINE,
	wait = 16,
}
ai.neededSpeed = 1
ai.priority = -25
ai.captureBufferSize = vector(200, 400)
ai.captureBuffer = setmetatable({}, {__index = function(self, key)
	local size = ai.captureBufferSize
	local captureBuffer = Graphics.CaptureBuffer(size.x, size.y)

	rawset(self, key, captureBuffer)
	return rawget(self, key)
end})

-- optimization
local math_abs = math.abs

-- constants
local GOING_NOWHERE = 0
local GOING_UP_RIGHT = -2
local GOING_UP_LEFT = 2

local ROTATIONS = {
	[GOING_UP_RIGHT] = -90,
	[GOING_UP_LEFT] = 90,
}

local BOUNCE_SPEED = {
	[GOING_UP_RIGHT] = vector(-16, -9),
	[GOING_UP_LEFT] = vector(16, -9),
}

local SPEED = {
	[GOING_UP_RIGHT] = vector(0, -3),
	[GOING_UP_LEFT] = vector(0, -3),
}

local ALLOWED_KEYS = table.map{
	"run",
	"altJump",
	"jump",
	"altRun"
}

local ADDRESSES = {
	[GOING_UP_LEFT] = 0x148, 
	[GOING_UP_RIGHT] = 0x14C,
}

function ai.register(id)
	ai.idMap[id] = true
end

function ai.canRun(slopeBlock, p)
	local cfg = Block.config[slopeBlock.id]

	-- if math_abs(p.speedX) < ai.neededSpeed then return end

	if cfg.floorslope == -1 then
		return p:mem(0x14C, FIELD_WORD) > 0, GOING_UP_RIGHT, "right"
	elseif cfg.floorslope == 1 then
		return p:mem(0x148, FIELD_WORD) > 0, GOING_UP_LEFT, "left"
	end
end

function ai.stop(p, playerData, bounce)
	if playerData.state ~= GOING_NOWHERE then
		if bounce then
			local rotation = math.rad(playerData.rotation)
			local speed = BOUNCE_SPEED[playerData.state]

			p.speedX = speed.x
			p.speedY = speed.y
		end

		playerData.state = GOING_NOWHERE
		ai.rotate(p, playerData)

		Routine.run(function()
			Routine.waitFrames(ai.rotationSettings.wait)
			p.data._triangular = nil
		end)
	end
end

function ai.animation(p, playerData)
	-- local i = 1

	-- if p.holdingNPC then
	-- 	i = 2
	-- end

	playerData.frameTimer = playerData.frameTimer + 1
	if p.speedY > Defines.player_walkspeed - 1.5 or p.speedY < -Defines.player_walkspeed + 1.5 then
		playerData.frameTimer = playerData.frameTimer + 1 end
	if p.speedY > Defines.player_walkspeed or p.speedY < -Defines.player_walkspeed then
		playerData.frameTimer = playerData.frameTimer + 1 end
	if p.speedY > Defines.player_walkspeed + 1 or p.speedY < -Defines.player_walkspeed - 1 then
		playerData.frameTimer = playerData.frameTimer + 1 end
	if p.speedY > Defines.player_walkspeed + 2 or p.speedY < -Defines.player_walkspeed - 2 then
		playerData.frameTimer = playerData.frameTimer + 1 end

	if playerData.frameTimer >= 15 then
		playerData.frameTimer = 0
		if playerData.frame == 1 then playerData.frame = 2 else playerData.frame = 1 end
	end
end

-- checks if player should be able to walk on walls/ceilings
function ai.check(p, playerData)
	if ADDRESSES[playerData.state] == nil then return end

	if p:mem(ADDRESSES[playerData.state], FIELD_WORD) <= 0 then
		return false
	end

	return true
end

function ai.rotate(p, playerData, offset, rot)
	local rotationSettings = ai.rotationSettings

	local offset = offset or vector(0, 0)

	if playerData.state == GOING_UP_RIGHT or playerData.state == GOING_UP_LEFT then
		offset = vector(((p.height - p.width) * .5) * -p.direction, 0)
	end

	transition.to(playerData, rotationSettings.wait, rotationSettings.easing, 
		{
			rotation = ROTATIONS[playerData.state] or rot or 0,
			offset = offset,
		}
	)
end

function ai.main(p)
	local slopeIdx = p:mem(0x48, FIELD_WORD)

	local playerData = p.data._triangular

	if slopeIdx > 0 then
		local slopeBlock = Block(slopeIdx)
		local canRun, state, key = ai.canRun(slopeBlock, p)

		if playerData == nil and canRun then
			p.data._triangular = {
				oldState = 0,
				state = state,
				savedState = nil,
				key = key,
				rotation = 0,
				offset = vector(0, 0),
				frameTimer = 0,
				frame = 1,
				canJump = 0,
			}

			playerData = p.data._triangular

			local speed =SPEED[playerData.state]

			p.speedX = speed.x
			p.speedY = speed.y
		end
	end

	if playerData == nil then return end

	local collidesLeft = p:mem(0x148, FIELD_WORD)
	local collidesRight = p:mem(0x14C, FIELD_WORD)
	local collidesTop = p:mem(0x14A, FIELD_WORD)
	local collidesBottom = p:mem(0x146, FIELD_WORD)

	p:mem(0x142, FIELD_BOOL, true)
	ai.animation(p, playerData)

	if p.keys.jump and playerData.state ~= GOING_NOWHERE then
		SFX.play(1)
		return ai.stop(p, playerData, true)
	end

	if not ai.check(p, playerData) then
		return ai.stop(p, playerData)
	end 

	if playerData.state == GOING_UP_RIGHT or playerData.state == GOING_UP_LEFT then
		local neededKey = playerData.key
		local continue = false

		if p.keys[neededKey] then
			continue = true
		end

		if continue then
			p.speedY = p.speedY - (0.15 + Defines.player_grav)
		else
			ai.stop(p, playerData)
		end
	end

	if playerData.oldState ~= playerData.state then
		ai.rotate(p, playerData)
		playerData.oldState = playerData.state
	end

	-- Text.print(tostring(p.height - p.width), 10, 10)
end

function ai.onTickEnd()
	for k,p in ipairs(Player.get()) do
		ai.main(p)
	end
end

local pRenderArgs = {
	sceneCoords = false,
	ignorestate = true,
	-- direction = -1,
}

local drawArgs = {
	sceneCoords = true,
	centered = true,
}

function ai.draw(p)
	local playerData = p.data._triangular

	if playerData == nil then return end

	local buffer = ai.captureBuffer[p]
	local priority = ai.priority

	buffer:clear(priority)

	pRenderArgs.target = buffer
	pRenderArgs.x = buffer.width * .5 - p.width * .5
	pRenderArgs.y = buffer.height * .5 - p.height * .5
	pRenderArgs.priority = priority
	pRenderArgs.frame = playerData.frame

	p:render(pRenderArgs)

	drawArgs.texture = buffer
	drawArgs.x = (p.x + p.width * .5) + (playerData.offset.x)
	drawArgs.y = (p.y + p.height * .5) + (playerData.offset.y)
	drawArgs.rotation = playerData.rotation
	-- drawArgs.width = buffer.width * -p.direction

	drawArgs.priority = priority

	Graphics.drawBox(drawArgs)
end

function ai.onCameraDraw()
	for k,p in ipairs(Player.get()) do
		ai.draw(p)
	end
end

function ai.onInitAPI()
	registerEvent(ai, 'onTickEnd')
	registerEvent(ai, 'onCameraDraw')
end

return ai