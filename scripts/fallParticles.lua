local fallParticles = {}

function fallParticles.onStart()
	for k,v in ipairs(Player.get()) do
		v.data._fell = 0
	end
end

local flapSound = Misc.resolveSoundFile("birdflap")

function fallParticles.run(v)
	SFX.play(flapSound, 0.25)

	Effect.spawn(999, v.x - 16, v.y + v.height - 16)
	Effect.spawn(999, v.x + v.width, v.y + v.height - 16)
end

function fallParticles.onTickEnd()
	for k,v in ipairs(Player.get()) do
		local data = v.data

		if not v:isOnGround() and data._fell == 0 then
			data._fell = 1
		elseif v:isOnGround() and data._fell == 1 then
			fallParticles.run(v)
			data._fell = 0
		end 
	end
end

function fallParticles.onInitAPI()
	registerEvent(fallParticles, 'onStart')
	registerEvent(fallParticles, 'onTickEnd')
end

return fallParticles