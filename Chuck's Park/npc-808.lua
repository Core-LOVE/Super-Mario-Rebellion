local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")
local colliders = require("Colliders")

local cyclingChuck = {}
local npcID = NPC_ID;



--***************************************************************************************************
--                                                                                                  *
--              				Movement code by Eclipsed											*
--								Rotation code by MrDoubleA  										*
--                Thanks to KBM-Quine for helping me with the slope rotation						*
--                      	                                                                        *
--***************************************************************************************************

local cyclingChuckSettings = {
	id = npcID, 
	gfxwidth = 64, 
	gfxheight = 68, 
	width = 32, 
	height = 48,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 5,
	framespeed = 8, 
	framestyle = 1,
	score = 0,
	nofireball = 0,
	noyoshi = 1,
	spinjumpsafe = true,
	npconhit = 311,
	jumpTime = 5.5
}

local configFile = npcManager.setNpcSettings(cyclingChuckSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=73,
[HARM_TYPE_FROMBELOW]=172,
[HARM_TYPE_NPC]=172,
[HARM_TYPE_HELD]=172,
[HARM_TYPE_TAIL]=172,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

-- Final setup
local function hurtFunction (v)
	v.ai2 = 0;
end

local function hurtEndFunction (v)
	v.data._basegame.frame = 0;
end

function cyclingChuck.onInitAPI()
	npcManager.registerEvent(npcID, cyclingChuck, "onStartNPC");
	npcManager.registerEvent(npcID, cyclingChuck, "onTickEndNPC");
	npcManager.registerEvent(npcID, cyclingChuck, "onDrawNPC");
	chucks.register(npcID, hurtFunction, hurtEndFunction);
	registerEvent(cyclingChuck, "onNPCHarm");
	registerEvent(cyclingChuck, "onNPCKill");
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

--Set certain variables on start of level
function cyclingChuck.onStartNPC(v)
	local data = v.data
	v.speedX = 0.5 * v.direction
	if v.direction == DIR_LEFT then
		v.ai5 = 10
	else
		v.ai5 = -10
	end
end

local slopeRotation = 0

local function drawSprite(args) -- handy function to draw sprites (MrDoubleA wrote this)
	args = args or {}

	args.sourceWidth  = args.sourceWidth  or args.width
	args.sourceHeight = args.sourceHeight or args.height

	if sprite == nil then
		sprite = Sprite.box{texture = args.texture}
	else
		sprite.texture = args.texture
	end

	sprite.x,sprite.y = args.x,args.y
	sprite.width,sprite.height = args.width,args.height

	sprite.pivot = args.pivot or Sprite.align.TOPLEFT
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.TOPLEFT
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

function cyclingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	
	if not data.rotation then
		data.rotation = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then data.rotation = 0 return end
	
	-- initializing
	if (v:mem(0x12A, FIELD_WORD) <= 0 --[[or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL)]] or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = configFile.health; -- Health
		v.ai2 = 0;
		data.jump = data.jump or 50
		v.ai3 = 1
		data.currentlyOnSlope = data.currentlyOnSlope or false
		--Set up a collider
		data.detectBox = colliders.Box(v.x, v.y, v.width, v.height * 0.5 + 1);
		
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = 0,
			frames = configFile.frames
		})
		return
	end
	if (data.exists == nil) then
		v.ai1 = configFile.health;
		data.exists = 0;
		data.frame = 0;
	end
	
	--Move collider with NPC
	data.detectBox.x = v.x
	data.detectBox.y = v.y + 24
	
	local collidingBlocks = Colliders.getColliding{
    a = data.detectBox,
    b = Block.SOLID .. Block.SEMISOLID .. Block.PLAYER,
    btype = Colliders.BLOCK,
	}
	
	for _,block in pairs(collidingBlocks) do
		if Block.config[block.id].floorslope ~= 0 then
			if v.speedY <= 0 then
				slopeRotation =	(1 - Block.config[block.id].height / Block.config[block.id].width * 50 * v.direction)
			else
				slopeRotation =	(1 - Block.config[block.id].height / Block.config[block.id].width * -50 * v.direction)
			end
		else
			slopeRotation = 0
		end
		data.rotation = slopeRotation
	end
	
	--Timer for turning animation - If it's facing left then the timer goes up, and if facing right it goes down. The turning animation frames depend on this.
	if v.ai5 < 10 and v.direction == DIR_LEFT then
		v.ai5 = v.ai5 + 1
	elseif v.ai5 > -10 and v.direction == DIR_RIGHT then	
		v.ai5 = v.ai5 - 1
	end
	
	--Timer start and apply chasing AI
	v.ai2 = v.ai2 + 1
	
	if v.ai4 > 0 then
		v.ai4 = v.ai4 - 1
	end
	
	--Randomly switch between cycling and doing sick wheelies
	if not v.dontMove then
		if v.collidesBlockBottom then
			data.rotation = slopeRotation
			
			chasePlayers(v)
			v.speedX = math.clamp(v.speedX + 0.2 * data.direction, -7, 7)
			data.jump = 0
			if v.speedX >= 0.5 or v.speedX <= -0.5 then
				if v.ai2 >= RNG.random(256,320) then
					data.rnd = RNG.random()
					if data.rnd >= 0.25 then
						v.ai4 = 64
					end
					v.ai2 = 0
				end
				if v.ai4 <= 0 then
					data.frame = math.floor(lunatime.tick() / 8) % 2;
				else
					data.frame = 4;
				end
			else
				--There's that timer being put to use
				if data.frame ~= 4 then
					if v.ai5 > 0 then
						data.frame = 2;
					else
						data.frame = 3;
					end
				end
			end
		else
			data.jump = data.jump + 1
			data.frame = 4;
			slopeRotation = 0
		end
	else
		--If standing still make it sit there so it doesnt look weird
		data.frame = 0;
	end

	--Make it do a jump and a flip when it goes midair
	if data.jump == 1 then
		data.rotation = 0
		v.speedY = -cyclingChuckSettings.jumpTime
	elseif data.jump >= 32 and data.jump <= 44 then
		data.rotation = ((data.rotation or 0) + math.deg((6 * v.direction)/((v.width+v.height)/-6)))
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames
	});
end

function cyclingChuck.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if reason == HARM_TYPE_JUMP and v.ai2 == 0 then
		Animation.spawn(npcID, v.x, v.y + 16)
		v.ai3 = 0
	end
end

function cyclingChuck.onNPCKill(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	Animation.spawn(npcID, v.x, v.y + 16)
end

function cyclingChuck.onDrawNPC(v)
	local data = v.data._basegame
	local config = NPC.config[v.id]

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end

	local priority = -45
	if config.priority then
		priority = -15
	end
	
	if v.ai3 == 1 then
		drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
		}
		npcutils.hideNPC(v)
	end
end

return cyclingChuck;