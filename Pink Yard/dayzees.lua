local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")
local npcutils = require("npcs/npcutils")

--*******************************************************************
--Based off of an old .dll NPC made by Enjl, edited and changed by me
--*******************************************************************

local dayzees = {}
local npcIDs = {}

local STATE_STROLL = 0
local STATE_SIT = 1
local STATE_SHOOT = 2

local frameTimer = 0

local spawnOffset = {}
spawnOffset[-1] = 22
spawnOffset[1] = -12

local musicEmitter = {
	[-1] = Particles.Emitter(0,0,Misc.resolveFile("p_noteR.ini")),
	[1] = Particles.Emitter(0,0,Misc.resolveFile("p_noteL.ini"))
}

--Register events
function dayzees.register(id)
	npcManager.registerEvent(id, dayzees, "onTickEndNPC")
	npcIDs[id] = true
end

function dayzees.onInitAPI()
    registerEvent(dayzees, "onNPCHarm")
	registerEvent(dayzees, "onDraw")
end

--Controlling the petal effect
function effectconfig.onTick.TICK_PETAL(v)
	if v.animationFrame < 4 then
		v.framespeed = 1
	elseif v.animationFrame >= 4 and v.animationFrame < 9 then
		v.framespeed = 3
	else
		v.framespeed = 4
	end
end

function dayzees.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	local config = NPC.config[v.id]
	if not npcIDs[v.id] then return end
	
	if reason ~= HARM_TYPE_OFFSCREEN then
		Effect.spawn(v.id, v.x - 24, v.y - 32, player.section, true)
	end
end

function dayzees.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.state = STATE_STROLL
		data.timer = 0
		data.countTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_STROLL
		if v.ai1 == 0 then
			v.ai1 = v.direction
		end
		data.timer = data.timer or 0
		data.countTimer = data.countTimer or 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_STROLL
		data.timer = 1
	end

	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 then
		v.ai1 = 0 --direction storage
		v.ai2 = 0 --oopsie timer
		v.ai3 = 0 --music timer
		return
	end
	
	if data.state == STATE_SIT then
		v.ai2 = v.ai2 - 1
		v.speedX = 0
		if v.ai2 >= 60 then
			v.animationFrame = math.floor(v.ai2 / 4) % 2 + 13
		elseif v.ai2 < 60 and v.ai2 >= 48 then
			v.animationFrame = 12
		elseif v.ai2 < 48 and v.ai2 > 0 then
			if v.ai2 % 32 < 16 then
				v.animationFrame = 12
			else
				v.animationFrame = 13
			end
		else
			data.state = STATE_STROLL
			v.ai2 = 0
		end
	elseif data.state == STATE_STROLL then
		--Frames - If being thrown display something different
		if v:mem(0x136, FIELD_BOOL) then
			v.animationFrame = 8
		else
			v.ai3 = v.ai3 + 1
			v.ai4 = v.ai4 + 1
			v.speedX = 0.6 * v.direction
			v.animationFrame = math.floor(v.ai4 / 6) % 12
		end
		
		if NPC.config[v.id].bubbleDayzee then
			data.countTimer = data.countTimer + 1
			if data.countTimer >= RNG.random(86,360) then
				data.state = STATE_SHOOT
				data.countTimer = 0
			end
		end
		
		--Emit the music note particles
		if v.ai3 >= 40 then
			musicEmitter[v.ai1].x = v.x + 0.5 * v.width
			musicEmitter[v.ai1].y = v.y + 10
			musicEmitter[v.ai1]:Emit(1)
			v.ai3 = 0
		end
		
		--If the NPC turns around
		if v.ai1 == -v.direction or data.timer > 0 then
			data.timer = 0
			data.state = STATE_SIT
			v.ai2 = 76
			v.ai1 = v.direction
		end
	else
		v.speedX = 0
		data.countTimer = data.countTimer + 1
		if data.countTimer <= 7 then
			v.animationFrame = 12
		else
			v.animationFrame = 14
		end
		
		if data.countTimer == 8 then
			npcutils.faceNearestPlayer(v)
			v.direction = -v.direction
		elseif data.countTimer >= 31 then
			if data.countTimer % 3 == 0 then
				local n = NPC.spawn(NPC.config[v.id].projectile, v.x + spawnOffset[v.direction], v.y + 20)
				n.direction = -v.direction
				n.speedX = RNG.random(5,5.5) * n.direction
				n.ai1 = RNG.random(16,24)
			end
		end
		if data.countTimer >= 63 then
			npcutils.faceNearestPlayer(v)
			data.countTimer = 0
			v.ai1 = v.direction
			data.state = STATE_STROLL
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = NPC.config[v.id].frames
	});
end

function dayzees.onDraw(v)
	for k,v in pairs(musicEmitter) do
		v:Draw(-40, true)
	end
end

return dayzees