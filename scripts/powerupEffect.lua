local collectEffect = {}

local transition = require("transition")
local blendmode = require("blendmode")

collectEffect.entries = {}
collectEffect.default = {
	color = Color.yellow,

	radius = 0,
	maxRadius = 65,
	alpha = 1,
	time = 65,
}

local powerupHandlers = {}

powerupHandlers[185] = {
	color = Color.red,
}

function collectEffect.spawn(v, p)
	local v = table.append({
		x = v.x + v.width * .5,
		y = v.y + v.height * .5,
	}, collectEffect.default)

	transition.to(v, v.time, transition.EASING_LINEAR, {radius = maxRadius, alpha = 0})

	table.insert(collectEffect.entries, v)
	return v
end

function collectEffect.onPostNPCCollect(v, p)
	if NPC.config[v.id].iscoin or powerupHandlers[v.id] then
		collectEffect.spawn(v, p)
	end
end

function collectEffect.onCameraDraw()
	for k,v in ipairs(collectEffect.entries) do
		local shader, uniforms = blendmode.get("add")

		Graphics.drawCircle{
			x = v.x,
			y = v.y,
			radius = v.radius,
			color = v.color .. v.alpha,
			shader = shader,
			uniforms = uniforms,
		}
	end
end

function  collectEffect.onInitAPI()
	registerEvent(collectEffect, 'onNPCCollect')
	registerEvent(collectEffect, 'onCameraDraw')
end

return collectEffect