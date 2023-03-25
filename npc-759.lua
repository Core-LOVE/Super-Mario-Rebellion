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


local normalID = (npcID - 2)
local stunnedID = (npcID - 1)
local deathEffectID = (npcID - 6)


local galoombaSettings = table.join({
	id = npcID,
	
	gfxwidth = 72,
	gfxheight = 50,

	gfxoffsetx = 0,
	gfxoffsety = 2,
	
	width = 32,
	height = 32,
	
	frames = 4,
	framestyle = 1,
	framespeed = 8,

	galoombaType = ai.TYPE.WINGED,

	normalID = normalID,
	stunnedID = stunnedID,

	preHopTime = 15,
	hopCount = 3,
	hopSpeedSmall = -3,
	hopSpeedBig = -7,
	hopTurnsAround = true,

	wingFrames = 2,
	wingFramespeed = 8,

	speed = 1.2,
	cliffturn = true,
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