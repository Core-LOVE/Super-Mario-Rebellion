--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local colliders = require("Colliders")

--**************************
--Rotation code by MrDoubleA
--**************************

--Create the library table
local football = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local footballSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	frames = 3,
	framestyle = 0,
	framespeed = 8, 
	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,
	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(footballSettings)


--Register events
function football.onInitAPI()
	npcManager.registerEvent(npcID, football, "onTickEndNPC")
	npcManager.registerEvent(npcID, football, "onDrawNPC")
end

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

	sprite:draw{priority = -45,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

function football.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.keepSpeedY = 0
		data.rotation = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.keepSpeedY = data.keepSpeedY or 0
		data.detectBox = colliders.Box(v.x, v.y, v.width, v.height)
	end

	--Move collider with NPC
	data.detectBox.x = v.x
	data.detectBox.y = v.y
	
	--If used as a projectile, hurt the player
	if v.ai2 > 0 then
		v.noblockcollision = true
		for _,plr in ipairs(Player.get()) do
			if colliders.collide(plr, data.detectBox) then
				plr:harm()
			end
		end
	else
		--Soccer ball physics
		if not v.collidesBlockBottom then
			data.keepSpeedY = v.speedY - 1
		end
		
		if data.keepSpeedY < 0 then data.keepSpeedY = 0 end
		
		if v.collidesBlockBottom then
			v.speedY = -data.keepSpeedY
		end
		
		if v.speedX ~= 0 then
			if v.collidesBlockBottom then
				v.speedX = v.speedX - 0.05 * v.direction
			else
				v.speedX = v.speedX - 0.01 * v.direction
			end
		end
		
		for _,plr in ipairs(Player.get()) do
			if colliders.collide(plr, data.detectBox) then
			
				if plr.x < v.x then
					if v.speedX < 0 and plr.speedX < 0 then
						v.speedX = -v.speedX
					else
						v.speedX = plr.speedX * 1.7
					end
				else
					if v.speedX > 0 and plr.speedX > 0 then
						v.speedX = -v.speedX
					else
						v.speedX = plr.speedX * 1.7
					end
				end
				
				if plr.speedX == 0 then v.speedX = -v.speedX end
				
				if plr.speedY < 0 then
					v.speedY = plr.speedY * 1.6
				elseif plr.speedY > 0 then
					v.speedY = plr.speedY * -1
				end
				
				if (v.speedY > 0 and v.speedY < 7) and plr.speedY == 0 or plr.standingNPC then
					v.speedY = -6
				end
				
			end
		end
		
		--Turn around if hitting NPCS (Janky lol)
		for _,npc in ipairs(NPC.get()) do
			if colliders.collide(npc, data.detectBox) and not v.standingNPC and not NPC.config[npc.id].isinteractable and NPC.HITTABLE_MAP[npc.id] then
				v.speedX = -v.speedX
				if npc.dontMove then
					v.speedX = -v.speedX
				end
			end
		end
		--Hurt NPCs and activate ? blocks if moving at high enough speeds
		for _,p in NPC.iterateIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1) do
			if (v.speedX > 4 or v.speedX < -4) or (v.speedY > 6.5 or v.speedY < -6.5) then
				if NPC.HITTABLE_MAP[p.id] and p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) and p:mem(0x12C, FIELD_WORD) == 0 then
					p:harm(HARM_TYPE_HELD)
				end
			end
		end
		
		data.destroyCollider = data.destroyCollider or colliders.Box(v.x - 1, v.y + 1, v.width + 1, v.height - 1);
		data.destroyCollider.x = v.x + 0.5 * (2/v.width) * v.direction;
		if v.speedY >= 0 then
			data.destroyCollider.y = v.y + 8;
		else
			data.destroyCollider.y = v.y - 8;
		end
		
		local list = colliders.getColliding{
		a = data.destroyCollider,
		btype = colliders.BLOCK,
		filter = function(other)
			if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
				return false
			end
			return true
		end
		}
		if (v.speedX > 4 or v.speedX < -4) or (v.speedY > 6.5 or v.speedY < -6.5) then
			for _,b in ipairs(list) do		
				b:hit(true)	
			end
		end
	end

	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.rotation = nil
		return
	end

	if not data.rotation then
		data.rotation = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then data.rotation = 0 return end
	
	data.rotation = ((data.rotation or 0) + math.deg((v.speedX*footballSettings.speed)/((v.width+v.height)/2)))
	
	v.animationFrame = v.ai3 
	
	if settings.style == 0 then
	elseif settings.style == 1 then
		v.ai3 = 1
	else
		v.ai3 = 2
	end
end

function football.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end

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

--Gotta return the library table!
return football