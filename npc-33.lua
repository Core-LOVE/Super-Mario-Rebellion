local npc = {}

local specialFrames = require("scripts/specialFrames")
local npcManager = require("npcManager")

local sf = specialFrames.define(8)
sf.framespeed = 5
local npcId = NPC_ID

function npc.onTickEndNPC(v)
	v.animationFrame = sf.frame
end

function npc.onTick()
	sf:update(10)
end

function npc.onInitAPI()
	registerEvent(npc, 'onTick')
	npcManager.registerEvent(npcId, npc, "onTickEndNPC")
end

return npc