local npc = {}

local npcId = NPC_ID
local npcManager = require("npcManager")
local npc_animator = require("scripts/npc/animator")
local animationPal = require("scripts/animationPal")
local boss_ai = require("scripts/npc/boss_ai")

local animationSet = {
    idle = {1, 2, 3, 4, defaultFrameY = 1, frameDelay = 9},
   	standup = {1, 2, 3, 4, defaultFrameY = 2, frameDelay = 8, next = "idle"},
}

boss_ai.register(npcId, {

})

local boss = {
	phases = {
		[1] = {
			routine = function(v)

			end,
		}
	}
}

function npc.onTickEndNPC(v)
	local data = v.data

	if not data.initialized then
		npc_animator.animator(v, {
		    animationSet = animationSet,
		    startAnimation = "standup",

		    imageDirection = DIR_RIGHT,
		    frameWidth = 100,
		    frameHeight = 100,

		    offset = vector(0,36),
		    scale = vector(2,2),

		    texture = Graphics.loadImageResolved("graphics/boss/rebellion.png"),
		})

		boss_ai.initialize(v, boss)
		boss_ai.setPhase(v)

		data.initialized = true
	end
end

function npc.onDrawNPC(v)
	local data = v.data

	data.animator:update()
	npc_animator.drawAnimator(v)
end

function npc.onInitAPI()
	npcManager.registerEvent(npcId, npc, 'onDrawNPC')
	npcManager.registerEvent(npcId, npc, 'onTickEndNPC')
end

return npc