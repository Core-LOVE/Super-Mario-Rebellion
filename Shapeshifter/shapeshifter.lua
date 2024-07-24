local shapeshifter = {}

local handycam = require("handycam")
local easing = require("ext/easing")
local transition = require("transition")
local enchanced_camera = require("scripts/enchanced_camera")
local distortionEffects = require("scripts/distortionEffects")

shapeshifter.activated = {}
shapeshifter.npc = {}
shapeshifter.delay = {}

local souls = {}
local ribbon_ini = Misc.resolveFile("ribbon_soul.ini")
local sh = Shader()
sh:compileFromFile(nil, Misc.resolveFile("ringburner.frag"))

local npcIdList = {
	800, 801
}

function shapeshifter.createSoul(p, v)
	local soul = {
		x = p.x,
		y = p.y,
		target = v,
		t = 0,

		ringRadius = 0,
		ringOpacity = 1,
	}

	local trail = Particles.Ribbon(soul.x, soul.y, ribbon_ini)
	trail.enabled = true
	trail:Emit(1)

	soul.trail = trail

	table.insert(souls, soul)
	return soul
end

local function distance (x1, y1, x2, y2)
	local dx = x1 - x2
	local dy = y1 - y2
	return math.sqrt ( dx * dx + dy * dy )
end

function shapeshifter.canPass(p)
	return not shapeshifter.activated[p] and not shapeshifter.delay[p]
end

function shapeshifter.canActivate(p)
	return p.rawKeys.jump == KEYS_PRESSED
end

local function shake(p)
	distortionEffects.create{
		x = p.x + p.width * .5,
		y = p.y + p.height * .5,
		-- texture = distortionEffects.textures.circle,
		priority = 1,
		scale = 3,
	}
end

local function getName(npc)
	local data = npc.data

	if data.parent_name then return data.parent_name end

	return data.name
end

local function npcsNotEqual(npc, v)
	local data = v.data

	return (data.parent ~= npc and npc ~= v)
end

function shapeshifter.activate(p, v)
	p.forcedState = FORCEDSTATE_INVISIBLE
	
	shapeshifter.activated[p] = true
	shapeshifter.npc[p] = nil

	local npcList = NPC.get(npcIdList)

	table.sort(npcList, function(a, b)
		local d1 = distance(p.x, p.y, a.x, a.y)
		local d2 = distance(p.x, p.y, b.x, b.y)

		return (d2 > d1)
	end)

	for k,npc in ipairs(npcList) do
		if npcsNotEqual(npc, v) and getName(npc) == getName(v) then
			SFX.play("shapeshift.ogg", 0.75)

			for i = 1, 16 do
				Effect.spawn(800, p.x, p.y)
			end

			shake(p)

			local cam = handycam[p.idx]
			cam:transition{time = 0.75, targets = {npc.data.npc or npc}, ease = handycam.ease(easing.outCubic)}
			enchanced_camera.enabled = false
			enchanced_camera.get(p.idx).t = 0
			-- cam.targets = {npc.data.npc}

			local soul = shapeshifter.createSoul(p, npc.data.npc or npc)
			Routine.run(function()
				Routine.wait(0.25)
				soul.drawRing = true
				transition.to(soul, 72, easing.outCirc, {ringRadius = 96})
			end)

			Routine.run(function()
				Routine.wait(0.6)

				shake(p)

				if npc.id == 801 then
					p.x = npc.x
					p.y = npc.y
					p.forcedState = FORCEDSTATE_NONE
					p.forcedTimer = 0
					shapeshifter.activated[p] = false
					shapeshifter.delay[p] = 16
					cam.targets = nil
				else
					shapeshifter.npc[p] = npc.data.npc
				end
			end)

			break
		end
	end
end

function shapeshifter.onCameraDraw(camIdx)
	for k,v in ipairs(souls) do
		local target = v.target
		v.t = v.t + 0.025

		if target and target.isValid then
			v.x = math.lerp(v.x, target.x + (target.width * .5), (v.t > 1 and 1) or v.t)
			v.y = math.lerp(v.y, target.y + (target.height * .5), (v.t > 1 and 1) or v.t)
		end

		if v.t < 1 then
			if math.random() > 0.15 then
				Effect.spawn(800, v.x, v.y)
			end
		end

		if v.trail and v.t < 1 then
			v.trail.x = v.x
			v.trail.y = v.y
		end

		if v.t >= 1 then
			v.trail:Break()
		end

		if v.drawRing and v.ringOpacity > 0 and target and target.isValid then
			local cam = Camera(camIdx)

			v.ringOpacity = v.ringOpacity - 0.025

		    Graphics.drawScreen{
		        priority = -4,
		        shader = sh,
		        uniforms = {
		            center = {target.x - cam.x + 0.5 * target.width, target.y - cam.y + 0.5 * target.height},
		            radius = v.ringRadius * .25,
		            alpha = v.ringOpacity
		        }
		    }

		    Graphics.drawScreen{
		        priority = -4,
		        shader = sh,
		        uniforms = {
		            center = {target.x - cam.x + 0.5 * target.width, target.y - cam.y + 0.5 * target.height},
		            radius = v.ringRadius,
		            alpha = v.ringOpacity
		        }
		    }
		end

		v.trail:Draw(-5, true)

		if v.t > 2 then
			table.remove(souls, k)
		end
	end
end

function shapeshifter.onTickEnd()
	for p, v in pairs(shapeshifter.delay) do
		shapeshifter.delay[p] = shapeshifter.delay[p] - 1

		if shapeshifter.delay[p] <= 0 then
			shapeshifter.delay[p] = nil
		end
	end

	for p, npc in pairs(shapeshifter.npc) do
		if not npc.isValid then
			shapeshifter.npc[p] = nil
			p:kill()
			return 
		end

		p.x = npc.x
		p.y = npc.y

		if shapeshifter.canActivate(p) then
			shapeshifter.activate(p, npc)	
		end
	end
end

function shapeshifter.onInitAPI()
	registerEvent(shapeshifter, 'onTickEnd')
	registerEvent(shapeshifter, 'onCameraDraw')
end

return shapeshifter