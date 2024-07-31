local betterReserve = {}

local npcutils = require("npcs/npcutils")
local transition = require("transition")
local npcs = {}

local settings = {
	easing = transition.EASING_OUTSINE,
	wait = 65,
}

function betterReserve.onInputUpdate()
	for k,v in ipairs(Player.get()) do
		local reserve = v.reservePowerup

		if v.keys.dropItem and reserve > 0 then
			SFX.play(11)

			local cam = Camera(v.idx)
			local x, y = (cam.x + cam.width * .5), (cam.y + 44)

			local npc = NPC.spawn(reserve, x, y)
			npc.x = npc.x - npc.width * .5
			npc.y = npc.y - npc.height * .5
			npc.forcedState = 2

			Routine.run(function()
				transition.to(npc, settings.wait, settings.easing, {x = v.x, y = v.y})

				Routine.waitFrames(settings.wait)

				npc.forcedState = 0
				npc.forcedCounter1 = 0
				npc.forcedCounter2 = 0
				npcs[npc] = nil
			end)

			npcs[npc] = true

			v.reservePowerup = 0
		end
	end
end

function betterReserve.onNPCCollect(e, v, p)
	if npcs[v] then
		e.cancelled = true
	end
end

function betterReserve.onCameraDraw(camIdx)
	for v in pairs(npcs) do
		if v and v.isValid then
			if math.random() > 0.5 then
				npcutils.drawNPC(v, {
					opacity = 0.75
				})
			end

			if math.random() > 0.6 then
				Effect.spawn(993, v.x + math.random(v.width), v.y + math.random(v.height))
			end

			npcutils.hideNPC(v)
		else
			npcs[v] = nil
		end
	end
end

function betterReserve.onInitAPI()
	-- registerEvent(betterReserve, 'onTick')
	registerEvent(betterReserve, 'onCameraDraw')
	registerEvent(betterReserve, 'onInputUpdate')
	registerEvent(betterReserve, 'onNPCCollect')
end

return betterReserve 