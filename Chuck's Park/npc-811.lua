--[[

	Written by MrDoubleA
	Please give credit!

    Part of MrDoubleA's NPC Pack

]]
local switchcolors = require("switchcolors")
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local messageBlock = {}
local npcID = NPC_ID

local messageBlockSettings = {
	id = npcID,
	
	gfxwidth = 64,
	gfxheight = 64,

	-- gfxoffsetx = 16,
	-- gfxoffsety = 16,
	
	width = 64,
	height = 64,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	-- npcblock = true,
	-- npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	-- playerblock = true,
	-- playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,


	bumpStartSpeed = -7,
	bumpGravity = 0.3,

	bumpStretchUp = 0.035,
	bumpStretchDown = -0.06,
	bumpStretchLanded = 0.12,

	bumpSound = 32,
}

npcManager.setNpcSettings(messageBlockSettings)
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{}
)


local littleDialogue
pcall(function() littleDialogue = require("littleDialogue") end)


function messageBlock.onInitAPI()
	npcManager.registerEvent(npcID, messageBlock, "onTickNPC")
	npcManager.registerEvent(npcID, messageBlock, "onDrawNPC")
	npcManager.registerEvent(npcID, messageBlock, "onInputUpdateNPC")

	registerEvent(messageBlock,"onNPCHarm")
end


local function initialise(v,data)
	data.bumpOffset = 0
	data.bumpSpeed = 0
	data.bumpActive = false

	data.stretch = 0

	data.cooldown = 0

	if v.msg ~= "" then
		data.message = v.msg
		v.msg = ""
	elseif data.message == nil then
		data.message = " "
	end
end

local function startBump(v)
	local config = NPC.config[v.id]
	local data = v.data

	if data.bumpActive or data.cooldown > 0 then
		return
	end

	data.bumpOffset = 0
	data.bumpSpeed = config.bumpStartSpeed
	data.bumpActive = true

	data.stretch = 0

	data.cooldown = 24

	SFX.play(config.bumpSound)

	switchcolors.switch(810, 809)
	-- Misc.pause(true)
end


function messageBlock.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	local config = NPC.config[v.id]

	if not data.initialized then
		data.initialized = true

		initialise(v,data)
	end

	data.cooldown = math.max(0,data.cooldown - 1)

	for _,p in NPC.iterate(810) do
		if Colliders.speedCollide(v,p) then
			startBump(v)
		end
	end
end


function messageBlock.onInputUpdateNPC(v) -- nobody uses this but it is useful for this
	if v.despawnTimer <= 0 or v.isHidden then return end

	local config = NPC.config[v.id]
	local data = v.data

	if not data.initialized then
		initialise(v,data)
	end

	-- Update the bump animation
	if data.bumpActive then
		data.bumpSpeed = data.bumpSpeed + config.bumpGravity
		data.bumpOffset = math.min(0,data.bumpOffset + data.bumpSpeed)

		if data.bumpOffset >= 0 then
			data.stretch = math.min(0,data.stretch + config.bumpStretchLanded)

			if data.stretch == 0 then
				data.bumpActive = false
				-- Misc.unpause()

				-- if littleDialogue ~= nil then
				-- 	littleDialogue.create{
				-- 		text = data.message,
				-- 		speakerObj = v,
				-- 	}
				-- else
				-- 	Text.showMessageBox(data.message)
				-- end
			end
		elseif data.bumpSpeed > 0 then
			data.stretch = math.max(-0.5,data.stretch + config.bumpStretchDown)
		else
			data.stretch = math.min(0.5,data.stretch + config.bumpStretchUp)
		end
	end
end


function messageBlock.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local config = NPC.config[v.id]
	local data = v.data

	if not data.initialized then
		initialise(v,data)
	end

	-- Render
	local texture = Graphics.sprites.npc[v.id].img

	local priority = (config.foreground and -15) or -45

	if data.sprite == nil or data.sprite.texture ~= texture then
		data.sprite = Sprite{texture = texture,frames = npcutils.getTotalFramesByFramestyle(v),pivot = Sprite.align.CENTRE}
	end

	data.sprite.x = v.x + v.width*0.5
	data.sprite.y = v.y + v.height - config.gfxheight*0.5 + data.bumpOffset

	data.sprite.scale.x = math.lerp(1,2,data.stretch)
	data.sprite.scale.y = math.lerp(1,0,data.stretch)

	data.sprite:draw{frame = v.animationFrame+1,priority = priority,sceneCoords = true}

	npcutils.hideNPC(v)
end


function messageBlock.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID or reason == HARM_TYPE_VANISH then return end

	startBump(v)

	eventObj.cancelled = true
end


return messageBlock