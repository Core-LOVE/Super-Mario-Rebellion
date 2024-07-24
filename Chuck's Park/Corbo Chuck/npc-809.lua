--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local playerStun = require("playerstun")
local colliders = require("Colliders")

--************************************************************
--After image effect by Enjl - used form his roto disk script.
--************************************************************

--Create the library table
local Corbo = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local CorboSettings = {
	id = npcID,
	gfxheight = 96,
	gfxwidth = 96,
	width = 44,
	height = 64,
	frames = 7,
	framestyle = 1,
	framespeed = 8, 
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	stunframes = 80,
	destroyblocktable = {90, 4, 188, 60, 293, 667, 457, 668, 526}
}

--Applies NPC settings
npcManager.setNpcSettings(CorboSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=npcID,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=npcID,
	}
);

local STATE_CHARGE = 0
local STATE_HURT = 1
local STATE_SOCCER = 2
local STATE_KICK = 3

local counter = 0

local function spawnBall(v)
	local n = NPC.spawn(npcID + 1, v.x, v.y + 32)
	n.ai2 = 1
	n.ai3 = RNG.randomInt(0,2)
	Effect.spawn(75, n.x, n.y)
	SFX.play(9)
	if counter % 2 == 0 then
		n.speedX = ((player.x+50) + (32 * v.direction) - (v.x+50))/100
		n.speedY = -11
	else
		n.speedX = ((player.x+20) - (v.x+50))/40
		n.speedY = -6
	end
end

--Functions relating to chasing players
local function getDistance(k,p)
	return k.x < p.x
end

local function setDir(dir, v)
	if (dir and v.data._basegame.direction == 1) or (v.data._basegame.direction == -1 and not dir) then return end
	if dir then
		v.data._basegame.direction = 1
	else
		v.data._basegame.direction = -1
	end
end

local function chasePlayers(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local dir1 = getDistance(v, plr)
	setDir(dir1, v)
end

--Register events
function Corbo.onInitAPI()
	npcManager.registerEvent(npcID, Corbo, "onTickEndNPC")
	npcManager.registerEvent(npcID, Corbo, "onDrawNPC")
	registerEvent(Corbo, "onNPCHarm")
	registerEvent(Corbo, "onNPCKill")
end

function Corbo.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_CHARGE
		data.timer = data.timer or 0
		data.attk = data.attk or RNG.randomInt(0,10)
		data.detectBox = colliders.Box(v.x, v.y, v.width, v.height)
	end
	
	data.detectBox.x = v.x
	data.detectBox.y = v.y
	
	if data.state == STATE_CHARGE then
		if v.ai2 == 0 then
			data.timer = data.timer + 1
		end
		if data.timer <= 32 then
			v.speedX = 0
			v.animationFrame = 5
			npcutils.faceNearestPlayer(v)
			if data.timer == 32 then
				-- 50% chance to instead perform a ground pound to stunlock the player
				if v.ai4 == 1 then
					if data.attk >= 7 then
						v.ai2 = v.ai2 + 1
						if v.collidesBlockBottom then
							if v.ai2 == 1 then
								v.speedY = -5.5
							elseif v.ai2 > 1 then
								v.ai2 = 0
								SFX.play(37)
								Defines.earthquake = 7
								for k, p in ipairs(Player.get()) do
									if p:isGroundTouching() and not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == player.section then
										playerStun.stunPlayer(k, CorboSettings.stunframes)
									end
								end
							end
						end
					elseif data.attk <= 6 and data.attk >= 4 then
						data.state = STATE_SOCCER
						data.timer = 2
						data.attk = 0
					end
				end
			end
		elseif data.timer > 32 and data.timer < 39 then
			v.animationFrame = 4
		else
			for _,n in ipairs(NPC.get()) do
				if colliders.collide(n, data.detectBox) then
					if n.id == npcID + 1 and ((math.abs(n.speedX) <= 1 and math.abs(n.speedY) <= 1) and n.ai2 == 0) then
						n.speedX = 0
						n.speedY = 0
						if v.x <= n.x then
							v.direction = 1
						else
							v.direction = -1
						end
						data.state = STATE_KICK
						data.timer = 0
					end
				end
			end
			--Leave a cool after trail
			if v.speedX >= 7 or v.speedX <= -7 then
				if lunatime.tick() % math.max(math.ceil(math.abs(4 - 0.5 * v.speedX)), 8) == 0 then
					local e = Effect.spawn(npcID + 2, v.x, v.y - 32)
					if v.direction == DIR_LEFT then
						e.animationFrame = 0
					else
						e.animationFrame = 1
					end
				end
			end
			
			-- Handle destroying blocks
			data.destroyCollider = data.destroyCollider or colliders.Box(v.x - 4, v.y + 8, v.width + 8, v.height - 8);
			data.destroyCollider.x = v.x - 2 + 0.5 * (v.width + 2) * v.direction;
			data.destroyCollider.y = v.y + 8;
			local list = colliders.getColliding{
			a = data.destroyCollider,
			b = CorboSettings.destroyblocktable,
			btype = colliders.BLOCK,
			filter = function(other)
				if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
					return false
				end
				return true
			end
			}
			for _,b in ipairs(list) do
				if v.speedX ~= 0 then
					if b.id == 667 then
						b:hit()
					else
						b:remove(true)
					end
				end
			end
			
			v.animationFrame = math.floor(lunatime.tick() / 8) % 2
			chasePlayers(v)
			v.speedX = math.clamp(v.speedX + 0.15 * data.direction, -8, 8)
		end
		--Timer to make it reset the waiting phase
		if data.timer >= 256 then data.timer = -8 end
		--After charging into a wall
		if v.collidesBlockLeft or v.collidesBlockRight then
			data.state = STATE_HURT
			Effect.spawn(npcID + 1, v.x, v.y)
			SFX.play(3)
			Defines.earthquake = 5
			data.timer = 0
		end
		--After running into a wall, be exposed to jumps
	elseif data.state == STATE_HURT then
		v.ai1 = 1
		data.timer = data.timer + 1
		v.speedX = 0
		if v.ai3 > 0 then
			v.animationFrame = -1
			v.ai3 = v.ai3 - 1
		else
			v.animationFrame = 6
		end
		--Enter its "Soccer" state, a force to be reckoned with.
		if data.timer > 128 then
			data.timer = 0
			v.ai3 = 0
			data.state = STATE_SOCCER
			data.attk = RNG.randomInt(0,10)
		end
	elseif data.state == STATE_SOCCER then
		v.ai1 = 0
		if v.ai2 == 0 then
			data.timer = data.timer + 1
		end

		if data.timer == 1 then
			v.animationFrame = 5
			v.ai2 = v.ai2 + 1
			if v.collidesBlockBottom then
				if v.ai2 > 1 then
					v.ai2 = 0
				else
					v.speedY = -7
					v.speedX = 5 * -v.direction
				end
			end
		else
			if data.timer >= 32 and data.timer <= 52 or data.timer >= 64 and data.timer <= 84 then
				v.animationFrame = 3
			else
				v.animationFrame = 2
			end
			v.speedX = 0
			npcutils.faceNearestPlayer(v)
		end
		if data.timer == 32 or data.timer == 64 then
			spawnBall(v)
			counter = counter + 1
		end
		if data.timer >= 90 then
			data.timer = 30
			data.state = STATE_CHARGE
		end
		--Only do this if it comes into contact with a stationary soccer ball
	else
		v.speedX = 0
		v.ai1 = 0
		
		if v.ai2 == 0 then
			data.timer = data.timer + 1
		end
		
		if data.timer >= 32 and data.timer <= 52 then
			v.animationFrame = 3
		else
			v.animationFrame = 2
		end
		
		for _,n in ipairs(NPC.get()) do
			if colliders.collide(n, data.detectBox) then
				if n.id == npcID + 1 then
				
					if v.x <= n.x then
						v.direction = 1
					else
						v.direction = -1
					end
				
					if data.timer == 32 then
						n.ai2 = 1
						n.speedX = ((player.x+20) - (v.x+50))/40
						n.speedY = -6
						Effect.spawn(75, n.x, n.y)
						SFX.play(9)
					end
				end
			end
		end
		if data.timer >= 58 then
			data.timer = 30
			data.state = STATE_CHARGE
		end
	end
	
	--Make link's sword not insta-kill him
	if v.ai5 > 0 then
		v.ai5 = v.ai5 - 1
		v.invincibleToSword = true
	else
		v.invincibleToSword = false
	end	
	
	-- animation controlling
	if v.ai3 == 0 then
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = CorboSettings.frames
		});
	end
end

function Corbo.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	local settings = v.data._settings
	if v.id ~= npcID then return end
	if not data.health then
		data.health = 90
	end
	if culprit then
		if culprit.__type == "NPC" then
			SFX.play(39)
			culprit:kill()
			if culprit.id == 13 or culprit.id == 108 or culprit.id == 17 then
				data.health = data.health - 5
			else
				data.health = data.health - 15
			end
		end
	elseif reason ~= HARM_TYPE_SWORD then
		for _,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
			if n.id == npcID + 1 then
				data.health = data.health - 15
				n:kill()
				SFX.play(39)
				Animation.spawn(10, n.x, n.y)
			end
		end
	end
	if reason == HARM_TYPE_SWORD then
		data.health = data.health - 6
		v.ai5 = 16
	elseif reason == HARM_TYPE_JUMP then
		culprit.speedX = 4 * -culprit.direction
		if v.ai1 == 1 then
			data.health = data.health - 11
			SFX.play(39)
			v.ai3 = 16
		else
			SFX.play(85)
		end
	end	
	if data.health <= 45 then
		v.ai4 = 1
	end
	if data.health > 0 then
		eventObj.cancelled = true
	end
end

function Corbo.onNPCKill(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if v.ai1 ~= 1 then
		Animation.spawn(npcID + 1, v.x, v.y)
	end
end

--Gotta return the library table!
return Corbo