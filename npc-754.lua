--[[

	Written by MrDoubleA
	Please give credit!

	Sleeping Galoomba Concept and Graphics by Thomas (https://www.smwcentral.net/?p=section&a=details&id=24079)

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ai = require("galoomba_ai")


local galoomba = {}
local npcID = NPC_ID


local stunnedID = (npcID + 1)
local deathEffectID = (npcID - 2)


local galoombaSettings = table.join({
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 2,
	
	width = 32,
	height = 32,
	
	frames = 5,
	framestyle = 1,
	framespeed = 5,

	galoombaType = ai.TYPE.SLEEPING,

	stunnedID = stunnedID,

	sleepFrames = 3,
	sleepFramespeed = 24,

	wakeDistance = 192,
	sleepDistance = 384,

	wakeUpSpeed = -6,

	acceleration = 0.1,
	deceleration = 0.05,
	speed = 5,

	staticdirection = true,
},ai.sharedSettings)

npcManager.setNpcSettings(galoombaSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = deathEffectID,
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
)

ai.register(npcID)

return galoomba