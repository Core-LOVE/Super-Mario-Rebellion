local boss_ai = {}

local npcManager = require("npcManager")

function boss_ai.register(id, args)
	local args = args or {}

	args.id = id

	npcManager.setNpcSettings(args)
end

function boss_ai.initialize(v, args)
	local data = v.data
	local args = args or {}

	data.phase = args.phase or 1
	data.phases = args.phases
	data.timer = args.timer or 0
end

function boss_ai.setPhase(v, num)
	local data = v.data

	data.phase = num or data.phase

	local phase = data.phases[data.phase]

	Routine.run(phase.routine, v, data)
end

function boss_ai.draw(v, camIdx)

end

return boss_ai