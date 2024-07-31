local collectEffect = {}

local transition = require("transition")
local blendmode = require("scripts/blendmode")

collectEffect.entries = {}
collectEffect.default = {
	color = Color.yellow,

	radius = 0,
	maxRadius = 72,
	alpha = 0.6,
	time = 42,

	doubled = true,
}

local powerupHandlers = {}

powerupHandlers[760] = {
	color = Color.green,
}

powerupHandlers[185] = {
	color = Color.red,
	alpha = 0.5,
	maxRadius = 128,
	radius = 32,
	time = 64,
	doubled = false,
}

powerupHandlers[183] = {
	color = Color.orange,
	alpha = 0.5,
	maxRadius = 128,
	radius = 32,
	time = 64,
	-- doubled = false,
}

function collectEffect.spawn(npc, p)
	local handler = powerupHandlers[npc.id] or {}
	local v = table.join({
		x = npc.x + npc.width * .5,
		y = npc.y + npc.height * .5,
	}, handler, collectEffect.default)

	transition.to(v, v.time, transition.EASING_LINEAR, {radius = v.maxRadius, alpha = -1})

	table.insert(collectEffect.entries, v)
	return v
end

function collectEffect.onPostNPCCollect(v, p)
	if NPC.config[v.id].iscoin or powerupHandlers[v.id] then
		collectEffect.spawn(v, p)
	end
end

function collectEffect.onCameraDraw()
    -- bg:captureAt(v.low)

	for k,v in ipairs(collectEffect.entries) do
		local shader, uniforms = blendmode.get("add")

		Graphics.drawCircle{
			x = v.x,
			y = v.y,
			radius = v.radius,
			color = v.color .. v.alpha,
			shader = shader,
			uniforms = uniforms,
			sceneCoords = true,
		}

		if v.doubled then
			Graphics.drawCircle{
				x = v.x,
				y = v.y,
				radius = v.radius * .5,
				color = v.color .. (v.alpha * .5),
				shader = shader,
				uniforms = uniforms,
				sceneCoords = true,
			}
		end

		if v.radius == v.maxRadius then
			table.remove(collectEffect.entries, k)
		end
	end
end

function  collectEffect.onInitAPI()
	registerEvent(collectEffect, 'onPostNPCCollect')
	registerEvent(collectEffect, 'onCameraDraw')
end

return collectEffect