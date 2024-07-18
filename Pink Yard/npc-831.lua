--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")

--*****************************************
--Interaction with player code by 8lueStorm
--*****************************************

--Create the library table
local bubble = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local bubbleSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 28,
	height = 28,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 5,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = true,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	
	ignorethrownnpcs = true,
}

--Applies NPC settings
npcManager.setNpcSettings(bubbleSettings)

--Register events
function bubble.onInitAPI()
	npcManager.registerEvent(npcID, bubble, "onTickEndNPC")
end

function effectconfig.onTick.TICK_BUBBLE_BURST(v)
	if v.animationFrame < 3 then
		v.framespeed = 2
	elseif v.animationFrame < 7 and v.animationFrame >= 3 then
		v.framespeed = 3
	elseif v.animationFrame == 7 then
		v.framespeed = 4
	elseif v.animationFrame == 8 or v.animationFrame == 9 then
		v.framespeed = 5
	else
		v.framespeed = 6
	end
end

function bubble.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	if v.ai1 > 0 then
		v.ai1 = v.ai1 - 1
	end
	v.ai2 = v.ai2 + 1
	if v.ai2 >= 40 then
		v:kill(9)
		Effect.spawn(npcID + 1, v.x, v.y, plr.section, true)
	end
	
	v.speedY = -1 - (v.ai1 / 8)
	v.speedX = 0 + (v.ai1 / 2) * v.direction
	
	--Animation controlling
	if v.ai2 < 8 then
		v.animationFrame = 0
	elseif v.ai2 >= 8 and v.ai2 <= 23 then 
		v.animationFrame = 1
	else
		v.speedX = 0
		v.ai1 = 0
		v.animationFrame = math.floor(lunatime.tick() / 4) % 4 + 1
	end
	
	--Push the player if it touches them
	if Colliders.collide(v,plr) and plr.deathTimer <= 0 then
		plr.speedY = -5
		SFX.play(Misc.resolveFile("bubblePop.wav"))
		plr.speedX = -plr.speedX * 1.5
		v:kill(9)
		Effect.spawn(npcID, v.x - 16, v.y - 16, plr.section, true)
	end
end

--Gotta return the library table!
return bubble